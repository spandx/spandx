Version 0.11.0

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Add `--format csv` option to scan command.
- Add `--format table` option to scan command.
- Add `--index` option to `index build` command.
- Add pypi index.
- Add maven index.

### Changed
- Change the default `--format` to `table` for the scan command.

## [0.11.0] - 2020-03-20
### Added
- Add `--format` option to scan command.
- Read from offline `nuget` cache.

## [0.10.1] - 2020-03-16
### Fixed
- Update location of `rubygems` index data

## [0.10.0] - 2020-03-16
### Added
- Include additional ruby gem spec metadata.
- Install `spandx-index` as an index source

## [0.9.0] - 2020-03-12
### Added
- Add `--airgap` option to disable network traffic during scan.
- Add `--logfile` option to redirect logger output to a file.

### Fixed
- Switch to directory of `Gemfile.lock` to bypass error with `Bundler.root`.

## [0.8.0] - 2020-03-11
### Added
- Allow scanning a directory.
- Allow recursive scanning of a directory.

## [0.7.0] - 2020-03-11
### Changed
- Improve how the `nuget` index is built.

## [0.6.0] - 2020-03-03
### Added
- Add `spandx index update` command to fetch the latest `spandx-rubygems` index.

### Removed
- Drop `spandx-rubygems` dependency.

### Changed
- Pull latest `spandx-rubygems` index via git.
- Perform binary search on CSV index.

## [0.5.0] - 2020-02-13
### Added
- Add jaro winkler string similarity support.
- Attempt to resolve rubygems dependencies via `spandx-rubygems` index.

### Changed
- Make `text` and `jaro_winkler` gems a soft dependency.

## [0.4.1] - 2020-02-02
### Fixed
- Save license expression as string instead of array.

## [0.4.0] - 2020-02-02
### Added
- Add command to build offline index of nuget packages and their licenses.

## [0.3.0] - 2020-01-29
### Added
- Add `pom.xml` parser

### Changed
- Change minimum ruby from 2.5 to 2.4

## [0.2.0] - 2020-01-28
### Added
- Parse .NET `sln` files
- Add ability to choose Levenshtein algorithm

## [0.1.7] - 2020-01-28
### Added
- Handle `nil` licenses from rubygems.org API response

## [0.1.6] - 2020-01-27
### Added
- Scan csproj files that depend on other project files
- Replace licensee dependency with simple tokenizer
- Fetch license data from git clone of SPDX license list data

## [0.1.5] - 2020-01-23
### Added
- Exclude `nil` licenses from report

## [0.1.4] - 2020-01-23
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

[Unreleased]: https://github.com/mokhan/spandx/compare/v0.10.1...HEAD
[0.10.1]: https://github.com/mokhan/spandx/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/mokhan/spandx/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/mokhan/spandx/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/mokhan/spandx/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/mokhan/spandx/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/mokhan/spandx/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/mokhan/spandx/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/mokhan/spandx/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/mokhan/spandx/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/mokhan/spandx/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/mokhan/spandx/compare/v0.1.7...v0.2.0
[0.1.7]: https://github.com/mokhan/spandx/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/mokhan/spandx/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/mokhan/spandx/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/mokhan/spandx/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/mokhan/spandx/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/mokhan/spandx/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/mokhan/spandx/compare/v0.1.0...v0.1.1
