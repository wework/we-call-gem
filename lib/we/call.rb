require 'faraday'
require 'faraday_middleware'
require 'faraday-sunset'
require 'typhoeus'

module We
  module Call
    autoload :Connection,    "we/call/connection"
    autoload :Configuration, "we/call/configuration"
    autoload :Middleware,    "we/call/middleware"
    autoload :VERSION,       "we/call/version"

    class << self
      attr_accessor :configuration
    end

    def self.configuration
      # potentially add in tracer here as param
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
