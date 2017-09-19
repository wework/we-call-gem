require "ruby_decorators"

module We
  module Call
    module Annotations
      # Enable annotations
      include RubyDecorators

      def self.extended(base)
        base.class_eval do
          # TODO Maybe this after_action could be a really simple call in base controllers
          # Having it here obviously ties We::Call to Rails, and is probably more than the annotations
          # class should be doing
          after_action do |controller|

            # TODO Maybe controller.class and params action could be passed to something in We::Call::Deprecated
            klass = controller.class
            method = params['action']
            deprecation = We::Call::Deprecated.get("#{klass}##{method}")

            if deprecation.present?
              # Shove a deprecation warning into the console or wherever it goes
              if defined? ActiveSupport
                ActiveSupport::Deprecation.warn("#{klass}##{method} is deprecated for removal on #{deprecation[:date].iso8601}")
              end

              # Shove a Sunset header into HTTP Response for clients to sniff on
              # https://tools.ietf.org/html/draft-wilde-sunset-header-03
              response.headers['Sunset'] = deprecation[:date].httpdate
            end
          end
        end
      end
    end
  end
end
