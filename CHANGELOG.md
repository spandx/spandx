Version 0.1.4

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

## [0.1.4] - 2020-01-22
### Added
- Add dependency on bundler
- Scan nuget `packages.config` files
- Scan dotnet `*.csproj` files
- Pull ruby gem license info from rubygems.org API V2.

## [0.1.3] - 2020-01-16
### Added
- Require `pathname`

## [0.1.2] - 2020-01-16
### Added
- Add CLI for `spandx scan <LOCKER>`
- Parse Gemfile.lock for dependencies.
- Parse Pipfile.lock for dependencies.
- Allow lookup for a specific license by id

## [0.1.1] - 2019-10-05
### Added
- Provide ruby API to the latest SPDX catalogue.

[Unreleased]: https://github.com/mokhan/spandx/compare/v0.1.4...HEAD
[0.1.3]: https://github.com/mokhan/spandx/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/mokhan/spandx/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/mokhan/spandx/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/mokhan/spandx/compare/v0.1.0...v0.1.1
