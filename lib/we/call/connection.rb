require 'typhoeus/adapters/faraday'

module We
  module Call
    module Connection
      extend self

      # If your network isn't stable enough to get a sign of life in 1s then you should look into that
      # Or override this default on creating the connection.
      OPEN_TIMEOUT = 1

      # We use typhoeus instead of default NetHTTP so we can control how many retries are made
      # https://github.com/lostisland/faraday/issues/612
      DEFAULT_ADAPTER_CLASS = Faraday::Adapter::Typhoeus
      DEFAULT_ADAPTER = :typhoeus

      DEFAULT_RETRY_OPTIONS = {
        max: 3,
        interval: 1,
        interval_randomness: 0.5,
        # After upgrading Faraday to 1.0+, use Faraday::Request::Retry::DEFAULT_EXCEPTIONS
        exceptions: [Faraday::ConnectionFailed, Errno::ETIMEDOUT, 'Timeout::Error', Faraday::TimeoutError]
      }

      class MissingApp < ArgumentError; end
      class MissingEnv < ArgumentError; end
      class MissingTimeout < ArgumentError; end
      class MissingOpenTimeout < ArgumentError; end

      QueryableBuilder = Class.new(Faraday::RackBuilder) do
        def adapter?
          @adapter || false
        end

        def adapter(key, *args, &block)
          super
          @adapter = key
        end

        def get_adapter
          @adapter || DEFAULT_ADAPTER
        end
      end

      # @param [Object] host
      # @param [Integer] timeout
      # @param [Integer] open_timeout
      # @param [String] app
      # @param [String] env
      # @yieldparam [Faraday::Connection] Faraday connection object is yielded to a block
      def new(host:, timeout: nil, open_timeout: OPEN_TIMEOUT, app: guess_app, env: guess_env, &block)
        @host = host
        @app = app or raise_missing_app!
        @env = env or raise_missing_env!
        @timeout = timeout or raise_missing_timeout!
        @open_timeout = open_timeout or raise_missing_open_timeout!
        create(&block)
      end

      private

      attr_reader :app, :env, :host, :timeout, :open_timeout

      # @return [Faraday::Connection] Preconfigured Faraday Connection object, for hitting get, post, etc.
      def create
        builder = QueryableBuilder.new(&Proc.new { |_| })

        headers = {
          'User-Agent'            => app,
          config.app_name_header  => app,
          config.app_env_header   => env,
        }

        request = {
          timeout:      timeout,
          open_timeout: open_timeout
        }

        Faraday.new(host, builder: builder, headers: headers, request: request) do |faraday|
          if config.detect_deprecations
            faraday.response :sunset, setup_sunset_middleware(faraday)
          end
          if config.retry
            faraday.request :retry, fetch_retry_options
          end

          yield faraday if block_given?

          unless adapter_handles_gzip?(faraday.builder.get_adapter)
            faraday.use :gzip
          end

          faraday.adapter DEFAULT_ADAPTER unless faraday.builder.adapter?
        end
      end

      def config
        We::Call.configuration
      end

      def raise_missing_app!
        raise MissingApp, 'app must be set, e.g: pokedex'
      end

      def raise_missing_env!
        raise MissingEnv, 'env must be set, e.g: staging'
      end

      def raise_missing_timeout!
        raise MissingTimeout, 'timeout must be set, maybe 5 (seconds) would be a good value. This is the open & read timeout, a.k.a max response time.'
      end

      def raise_missing_open_timeout!
        raise MissingOpenTimeout, 'open_timeout must be set, and defaults to 1 second. This is the time until a connection is established with another server, and after 1 sec it\'s probably not there.'
      end

      # @return [Boolean] Does the adapter handle gzip automatically or not
      # https://github.com/lostisland/faraday_middleware/blob/master/lib/faraday_middleware/gzip.rb#L9
      def adapter_handles_gzip?(adapter)
        [:em_http, :net_http, :net_http_persistent].include?(adapter)
      end

      def setup_sunset_middleware(faraday)
        options = { rollbar: :auto, active_support: :auto }
        # Pass something that might be a logger or anything with a warn method
        if config.detect_deprecations.respond_to?(:warn)
          options = options.merge({ logger: config.detect_deprecations })
        end
        options
      end

      def fetch_retry_options
        DEFAULT_RETRY_OPTIONS.merge(config.retry_options) do |key, default_val, new_val|
          if key == :exceptions
            default_val + Array(new_val)
          else
            new_val
          end
        end
      end

      # @return [String] Environment (usually 'development', 'staging', 'production', etc.)
      def guess_env
        return config.app_env if config.app_env
        ENV['RACK_ENV'] || rails_app_env
      end

      # @return [String] Check for config.app_name, or detect name from Rails application
      def guess_app
        return config.app_name if config.app_name
        ENV['APP_NAME'] || rails_app_name
      end

      def rails_app_env
        ::Rails.env if (defined? ::Rails)
      end

      def rails_app_name
        if (defined? ::Rails) && !::Rails.application.nil?
          ::Rails.application.class.parent_name.underscore.dasherize
        end
      end
    end
  end
end
