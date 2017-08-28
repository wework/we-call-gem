require "ruby_decorators"

module We
  module Call
    class Deprecated < RubyDecorator
      @@methods = {}

      def initialize(date:)
        @date = date
      end

      def set(method, value)
        @@methods[method] = value
      end

      def self.get(method)
        @@methods[method]
      end

      def self.methods
        @@methods
      end

      # Called when annotation is used
      def call(this, *args, &blk)
        set("#{this.owner}##{this.name}", date: normalize_datetime(@date))
        this.call(*args, &blk)
      end

      protected

      def normalize_datetime(datetime)
        datetime = DateTime.parse(datetime) if datetime.is_a? String
        datetime = datetime.to_datetime if datetime.respond_to? :to_datetime
        return datetime if datetime.respond_to? :httpdate
        raise TypeError, 'The date should be a Date, DateTime, Time or string containing a valid date and time'
      end
    end
  end
end
