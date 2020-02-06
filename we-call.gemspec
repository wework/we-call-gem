# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'we/call/version'

Gem::Specification.new do |spec|
  spec.name          = "we-call"
  spec.version       = We::Call::VERSION
  spec.authors       = ["WeWork Engineering"]
  spec.email         = ["engineering@wework.com"]

  spec.summary       = "Making healthy, happy HTTP calls"
  spec.description   = "Handles conventions of making calls to other services, with required metadata for tracking calls between services, deprecations of endpoints, trace IDs, throttling, etc."
  spec.homepage      = "https://github.com/wework/we-call-gem"
  spec.licenses      = ['MIT']

  spec.files                = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec)/})
  end
  spec.bindir               = "bin"
  spec.require_paths        = ["lib"]

  spec.add_dependency "typhoeus", "~> 1.3"
  spec.add_dependency "faraday", ">= 0.9.0", "< 1"
  spec.add_dependency "faraday_middleware", '~> 0.10'
  spec.add_dependency "faraday-sunset", '~> 0.2'

  spec.add_development_dependency "appraisal", "~> 2.0"
  spec.add_development_dependency "coveralls", '~> 0.7'
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rails", ">= 4.2"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "simplecov", '~> 0.15'
  spec.add_development_dependency "hashie", "~> 3.5"
  spec.add_development_dependency "vcr", '~> 5.1'
end
