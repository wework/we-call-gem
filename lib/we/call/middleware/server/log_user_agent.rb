module We
  module Call
    module Middleware
      module Server
        class LogUserAgent
          def initialize app
            @app = app
          end

          def call(env)
            line = "user_agent=#{env['HTTP_USER_AGENT']};"
            line += " app_name=#{env[incoming_app_name_header]};" if env[incoming_app_name_header]
            line += " app_env=#{env[incoming_app_env_header]};" if env[incoming_app_env_header]
            output(line)
            @app.call(env)
          end

          private

          def output(line)
            puts line
          end

          def config
            We::Call.configuration
          end

          def incoming_app_env_header
            @incoming_app_env_header ||= "HTTP_#{config.app_env_header.upcase.gsub!(/-/, '_')}"
          end

          def incoming_app_name_header
            @incoming_app_name_header ||= "HTTP_#{config.app_name_header.upcase.gsub!(/-/, '_')}"
          end
        end
      end
    end
  end
end
