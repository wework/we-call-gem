require 'faraday'
require 'faraday_middleware'

module We
  module Call
    class Configuration
      attr_accessor :app_env, :app_env_header, :app_name, :app_name_header, :detect_deprecations

      def initialize
        @app_env_header = 'X-App-Env'
        @app_name_header = 'X-App-Name'
        @detect_deprecations = true
      end
    end
  end
end
