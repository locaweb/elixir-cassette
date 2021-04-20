# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [UNRELEASED]
### Fixed
- Added `handle_info` as a `catch-all` clause that discards any unknown message.

## [1.5.1] = 2021-04-15
### Fixed
- Added `timeout` param to `Cassette.st` when `tgt` is expired

### Added
- Automatically expire validations with `Process.send_after/3`

### Changed
- Upgraded deps
- Revert credo configuration to default

### Removed
- Removed dogma tool (it's deprecated)

## [1.5.1] = 2018-10-19
### Fixed
- Name response type to result to avoid clash with `HTTPoison.Base` defined type

## [1.5.0] - 2018-10-11
### Added
- Add `timeout` param to `Cassette.st`, `Cassette.tgt` and `Cassette.validate`

## [1.4.1] - 2018-05-27
### Added
- Make `Cassette.Support.t` type to help dialyzer

## [1.4.0] - 2018-01-26
### Added
- `Cassette.User.t` now maps all CAS attributes
- Generate a Elixir 1.5+ compatible `child_spec/1` on `Cassette.Support` macro

### Fixed
- Compilation warnings on 1.5+

## [1.3.4] - 2018-01-09
### Changed
- Allow usage of httpoison 1.0

## [1.3.3] - 2017-12-20
### Changed
- Make spaces separating authorities optional

## [1.3.2] - 2017-03-14
### Changed
- Updated dependencies

## [1.3.1] - 2017-01-12
### Changed
- Removes compilation warnings on elixir 1.4.0

## [1.3.0] - 2016-06-30
### Changed
- `Cassette.Support.st/1` (and derivates) now retry (once) on an expired TGT

## [1.2.6] - 2016-06-16
### Changed
- changes request to `/serviceValidate` to `GET` method to comply with servers. See #1

## [1.2.5] - 2016-06-14
### Fixed
- Allows users with empty types

## [1.2.4] - 2016-06-09
### Fixed
- Fixes issues with environment variables when compiling the default cassette client

## [1.2.3] - 2016-06-09
### Fixed
 - Fixes issues with custom modules and environment variable configuration

## [1.2.2] - 2016-05-30
### Fixed
- Fixed a compile warning when using `Cassette.Support` macro with a custom config

## [1.2.1] - 2016-06-30
### Fixed
- Fixed issues reported by `credo`

## Changed
- Make `Cassette.Support` servers by `Application`s too

## [1.2.0] - 2016-05-25
### Added
- Macros on `Cassette.Support` now generate `start`, `start/2`
- Macros on `Cassette.Suport.child_spec/0` provide child spec for supervisors

## [1.1.0] - 2016-04-12
### Added
- support for the `cas:type` on `cas:attributes` (defaults to empty)

## [1.0.0] - 2016-01-06

### Added
- initial release with ticket generation, cache and validation
