# Changelog

akismet adheres to [SemVer 2.0.0](http://semver.org/spec/v2.0.0.html).

## 2.0.0 - 2014-02-14

### Added
* Short method aliases in `Client`, e.g. `spam` for `submit_spam`
* Class-level convenience methods in `Akismet`
* Blatant spam is reported via `Akismet#check`
* New method `Client#spam?`
* `Client#open` accepts a block
* Exceptions contain error messages returned by the Akismet API
* Better documentation; new README

### Changed
* New parameter names in `Client` instance methods
* Environment variables (e.g. HTTP headers) are passed as a hash in `env` parameter of `Client` instance methods
* `Client` instance methods raise exceptions if invalid parameters are passed
* `Client` instance methods format non-string parameters, e.g. a `DateTime` is formatted per ISO 8601
* `Client#check` returns two Boolean values: whether the comment is spam and whether it is blatant
* Parameter values are transcoded to UTF-8 if they have a different encoding
* Ruby 1.9.3+ required

## 1.0.2 - 2014-12-07

### Fixed
* Test failures with Ruby 2.0+

## 1.0.1 - 2014-12-05

### Fixed
* Gem won't build on Ruby 1.9+
* Runtime error when Akismet returns unexpected response body
* Typo in README
