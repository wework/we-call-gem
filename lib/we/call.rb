require 'faraday'
require 'faraday-sunset'
require 'typhoeus'

module We
  module Call
    autoload :Annotations,   "we/call/annotations"
    autoload :Connection,    "we/call/connection"
    autoload :Configuration, "we/call/configuration"
    autoload :Deprecated,    "we/call/deprecated"
    autoload :Middleware,    "we/call/middleware"
    autoload :VERSION,       "we/call/version"

    class << self
      attr_accessor :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
