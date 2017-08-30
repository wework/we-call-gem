require 'faraday'
require 'faraday_middleware'

module We
  module Call
    module Connection
      Faraday::Response.register_middleware detect_deprecations: We::Call::Middleware::Client::DetectDeprecations

      extend self

      OPEN_TIMEOUT = 2

      class MissingApp < ArgumentError; end
      class MissingEnv < ArgumentError; end
      class MissingTimeout < ArgumentError; end
      class MissingOpenTimeout < ArgumentError; end

      parent_builder_class = defined?(Faraday::RackBuilder) ? Faraday::RackBuilder : Faraday::Builder

      QueryableBuilder = Class.new(parent_builder_class) do
        def adapter?
          @has_adapter || false
        end

        def adapter(key, *args, &block)
          super
          @has_adapter = true
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

        Faraday.new(url: host, builder: builder) do |faraday|
          faraday.headers['User-Agent'] = app
          faraday.headers[config.app_name_header] = app
          faraday.headers[config.app_env_header] = env
          faraday.options[:timeout] = timeout
          faraday.options[:open_timeout] = open_timeout

          if config.detect_deprecations
            faraday.response :detect_deprecations, setup_deprecation_reporting(faraday)
          end

          yield faraday if block_given?

          faraday.adapter Faraday.default_adapter unless faraday.builder.adapter?
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

      def setup_deprecation_reporting(faraday)
        # In v0.5.0 this was a bool switch, now it takes :active_support or an instance of a Logger
        if config.detect_deprecations == true || config.detect_deprecations == :active_support
          return { active_support: true }

        # Pass something that might be a logger or anything with a warn method
        elsif config.detect_deprecations.respond_to?(:warn)
          return { logger: config.detect_deprecations }
        end
      end

      # @return [String] Environment (usually 'development', 'staging', 'production', etc.)
      def guess_env
        return config.app_env if config.app_env
        ENV['RAILS_ENV'] || ENV['RACK_ENV']
      end

      # @return [String] Check for config.app_name, or detect name from Rails application
      def guess_app
        return config.app_name if config.app_name
        return ENV['APP_NAME'] if ENV['APP_NAME']
        rails_app_name
      end

      def rails_app_name
        if (defined? ::Rails) && !::Rails.application.nil?
          ::Rails.application.class.parent_name.underscore.dasherize
        end
      end
    end
  end
end
