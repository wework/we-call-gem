# This class is going to be split into its own faraday-sunset soon, but I want to get the functionality nailed first
module We
  module Call
    module Middleware
      module Client
        class DetectDeprecations < Faraday::Middleware
          class NoOutputForWarning < StandardError; end

          # Initialize the middleware
          #
          # @param [Type] app describe app
          # @param [Hash] options = {}
          # @return void
          def initialize(app, options = {})
            super(app)
            @options = options
          end

          # @param [Faraday::Env] no idea what this does
          # @return [Faraday::Response] response from the middleware
          def call(env)
            @app.call(env).on_complete do |response_env|
              datetime = sunset_header(response_env.response_headers)
              report_deprecated_usage(env, datetime) unless datetime.nil?
            end
          end

          protected

          # Check to see if there is a Sunset header, which contains deprecation date
          #
          # @param [Faraday::Response] response object with headers and whatnot
          # @return [DateTime|nil] date time object of the expected deprecation date
          def sunset_header(headers)
            return if headers[:sunset].nil?
            DateTime.parse(headers[:sunset])
          end

          def report_deprecated_usage(env, datetime)
            if datetime > DateTime.now
              warning = "Endpoint #{env.url} is deprecated for removal on #{datetime.iso8601}"
            else
              warning = "Endpoint #{env.url} was deprecated for removal on #{datetime.iso8601} and could be removed AT ANY TIME"
            end
            send_warning warning
          end

          def send_warning(warning)
            warned = false
            if @options[:active_support]
              ActiveSupport::Deprecation.warn(warning)
              warned = true
            end
            if @options[:logger] && @options[:logger].respond_to?(:warn)
              @options[:logger].warn(warning)
              warned = true
            end
            unless warned
              raise NoOutputForWarning, "Pass active_support: true, or logger: ::Logger.new when registering middleware"
            end
          end
        end
      end
    end
  end
end
