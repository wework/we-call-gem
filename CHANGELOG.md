# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [v0.11.0] - 2020-12-08
### Added
- Allow to set retry options on a connection([#36])


## [v0.9.1] - 2020-11-20
### Added
- Automatically retry on network errors([#31])

[activesupport]: https://github.com/rails/rails/tree/master/activesupport
[#31]: https://github.com/wework/we-call-gem/pull/31

## [v0.9.0] - 2018-09-18
### Added
- Automatically reports deprecations to ActiveSupport if [activesupport] gem exists ([#21])
- Defaults detect_deprecations to nil instead of :active_support

[activesupport]: https://github.com/rails/rails/tree/master/activesupport
[#21]: https://github.com/wework/we-call-gem/pull/21

## [v0.8.0] - 2018-08-27
### Added
- Support for Ruby v2.5
- Support for Rails v5.2
- Support for Faraday v0.14 and v0.15
- Automatically reports deprecations to Rollbar if [rollbar] gem exists ([#17])

[rollbar]: https://github.com/rollbar/rollbar-gem
[#17]: https://github.com/wework/we-call-gem/pull/17

### Breaking
- Dropped support for Faraday v0.9 (may still work but its no longer tested or recommended)

## [v0.7.1] - 2018-02-20
### Fixed
- Call the gzip middleware to handle gzipped responses, which have been broken since v0.7 for typhoeus users

## [v0.7.0] - 2017-10-07
### Breaking Changes
- Removed `We::Call::Deprecated` and `We::Call::Annotations`. Deprecation logic is now handled by [rails-sunset] instead. I fully understand the irony of removing deprecation logic without deprecation

[rails-sunset]: https://github.com/wework/rails-sunset

## [v0.6.1] - 2017-10-03
### Fixed
- Required typhoeus in We::Call instead of connection, which loads it early enough for NewRelic tracing to kick in if you use that

### Changed
- Reduced open timeout default to 1 second

## [v0.6.0]
### Changed
- Use typhoeus instead of NetHTTP for a [series of reasons]

[typhoeus]: https://github.com/typhoeus/typhoeus
[series of reasons]: https://github.com/wework/we-call-gem/pull/7

## [v0.5.4]
### Fixed
- Connection checks `Rails.env` instead of `ENV['RAILS_ENV']` as most people dont have RAILS_ENV in their `.env` file

## [v0.5.3]

### Fixed
- Deprecations were calling a private method and failing

## [v0.5.2]

### Fixed
- Made Annotations require "ruby_decorators"

## [v0.5.1]

### Changed
- Switched `config.detect_deprecations` from bool to expect `:active_support` or logger instance
- Moved `We::Call::Middleware::Client::DetectDeprecations` into its own [faraday-sunset] gem (no BC breaks)

[faraday-sunset]: https://github.com/wework/faraday-sunset

## [v0.5.0]

### Added
- Configurable `We::Call.configure` which accepts a config block
- Config option `config.app_name` to avoid providing `app:` in every connection initializer
- Added the concept of Annotations. Simply `extend We::Call::Annotations` in a base controller to get cool stuff
- First annotation: `We::Call::Deprecated` added to mark controller methods as deprecated
- Added `We::Call::Middleware::Client::DetectDeprecations` that automatically registers as a faraday response middleware to report deprecated endpoints

### Changed
- Defaults to setting `X-App-Name` instead of `X-WeWork-App` (override with config.app_name_header)
- Defaults to setting `X-App-Env` instead of `X-WeWork-Env` (override with config.app_env_header)

### Fixed
- Switched from manually requiring to using module autoload to reduce memory footprint

## [v0.4.2]

### Fixed
- Manually setting `conn.adapter` would result in double adapters (two requests made!)

## [v0.4.1]

### Fixed
- Improved support for Faraday 0.8 - 0.9.

## [v0.4.0]

### Added
- `We::Call::Connection.new` requires `timeout: 1` where 1 is seconds.
- `We::Call::Connection.new` accepts `open_timeout: 1` where 1 is seconds.
