# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## v0.6.1
### Fixed
- Required typhoeus in We::Call instead of connection, which loads it early enough for NewRelic tracing to kick in if you use that

### Changed
- Reduced open timeout default to 1 second

## v0.6.0
### Changed
- Use typhoeus instead of NetHTTP for a [series of reasons]

[typhoeus]: https://github.com/typhoeus/typhoeus
[series of reasons]: https://github.com/wework/we-call-gem/pull/7

## v0.5.4
### Fixed
- Connection checks `Rails.env` instead of `ENV['RAILS_ENV']` as most people dont have RAILS_ENV in their `.env` file

## v0.5.3

### Fixed
- Deprecations were calling a private method and failing

## v0.5.2

### Fixed
- Made Annotations require "ruby_decorators"

## v0.5.1

### Changed
- Switched `config.detect_deprecations` from bool to expect `:active_support` or logger instance
- Moved `We::Call::Middleware::Client::DetectDeprecations` into its own [faraday-sunset] gem (no BC breaks)

[faraday-sunset]: https://github.com/philsturgeon/faraday-sunset

## v0.5.0

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

## v0.4.2

### Fixed
- Manually setting `conn.adapter` would result in double adapters (two requests made!)

## v0.4.1

### Fixed
- Improved support for Faraday 0.8 - 0.9.

## v0.4.0

### Added
- `We::Call::Connection.new` requires `timeout: 1` where 1 is seconds.
- `We::Call::Connection.new` accepts `open_timeout: 1` where 1 is seconds.
