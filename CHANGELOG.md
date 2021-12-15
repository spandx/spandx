Version 0.18.3

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.18.3] - 2021-12-15
- fix(spdx): fallback to online catalogue when local catalogue is not available.

## [0.18.2] - 2021-06-05
### Fixed
- fix(dpkg): detect package manager for related dependencies
- fix(terraform): detect package manager for related dependencies

## [0.18.1] - 2021-06-02
### Fixed
- Parse `.terraform.lock.hcl` files with multiple providers.

## [0.18.0] - 2021-05-10
### Added
- Add support for parsing `.terraform.lock.hcl` files.

## [0.17.0] - 2020-12-28
### Added
- Allow indexing gems from index.rubygems.org.

## [0.16.1] - 2020-11-19
### Fixed
- Start spinner for table printer only

## [0.16.0] - 2020-11-19
### Changed
- Pull smaller license cache.
- Print index files after building them.

## [0.15.1] - 2020-11-18
### Fixed
- Rebuild index after pulling latest cache.

## [0.15.0] - 2020-11-18
### Added
- Parse `/var/lib/dpkg/status` file.

## [0.14.0] - 2020-11-14
### Added
- Parse `/lib/apk/db/installed` file.

## [0.13.5] - 2020-05-26
### Fixed
- Process PyPI package urls with single digit versions.
- Remove unsupported `hash` report from help text.

### Changed
- Stream output to output stream as soon as results are available.
- Switch to `Oj` for JSON parsing.
- Run spinner on background thread.

## [0.13.4] - 2020-05-26
### Added
- Add detected file path to report output.

### Changed
- Use `Pathname` instead of `String` to represent file paths.
- Scan current directory when a path is not specified.

## [0.13.3] - 2020-05-19
### Fixed
- Ignore invalid URLs during scan.

## [0.13.2] - 2020-05-17
### Fixed
- Detect licenses when provided as an array.
- Skip empty lockfiles.

## [0.13.1] - 2020-05-16
### Fixed
- Add `ext/**/*.c` and `ext/**/*.h` to list of files.

## [0.13.0] - 2020-05-12
### Added
- Add progress bar
- Add SPDX expression parser.
- Add index for each cache.
- Update cache paths to point to Spandx organization.
- Add optimized CSV parser.
- Fetch dependency data concurrently.
- Add profiling and benchmarking tools.

### Changed
- Update git pull command to fetch master branch with a depth of 1.
- Update Nuget and PyPI cache builders to use same API for writing to cache.
- Update license lookup to parse SPDX expressions.

### Removed
- Drop Ruby 2.4 support.
- Drop Jaro Winkler algorithm.
- Drop Levenshtein algorithm.

### Fixed
- Fix bug in spawning worker threads in thread pool.
- Reset `http` global before each test to remove leakage between tests.

## [0.12.3] - 2020-04-19
### Fixed
- Ignore nuget entries with missing `items`.
- Remove require `etc`.

## [0.12.2] - 2020-04-18
### Fixed
- Insert entries with unknown license into cache instead of one large dead letter file that is too big to commit to git.

## [0.12.1] - 2020-04-17
### Fixed
- Revert ruby version constraint to support 2.4+

## [0.12.0] - 2020-04-14
### Added
- Add `--format csv` option to scan command.
- Add `--format table` option to scan command.
- Add `--index` option to `build` command.
- Add pypi index.
- Add maven index.
- Add support for parsing `yarn.lock` files.
- Add support for parsing `package-lock.json` files.
- Add `--pull` option to fetch latest cache before scan.
- Add support for parsing `composer.lock` files.
- Add support for loading custom plugins via the `--require` option.

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

[Unreleased]: https://github.com/spandx/spandx/compare/v0.18.3...HEAD
[0.18.3]: https://github.com/spandx/spandx/compare/v0.18.2...v0.18.3
[0.18.2]: https://github.com/spandx/spandx/compare/v0.18.1...v0.18.2
[0.18.1]: https://github.com/spandx/spandx/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/spandx/spandx/compare/v0.17.0...v0.18.0
[0.17.0]: https://github.com/spandx/spandx/compare/v0.16.1...v0.17.0
[0.16.1]: https://github.com/spandx/spandx/compare/v0.16.0...v0.16.1
[0.16.0]: https://github.com/spandx/spandx/compare/v0.15.1...v0.16.0
[0.15.1]: https://github.com/spandx/spandx/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/spandx/spandx/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/spandx/spandx/compare/v0.13.5...v0.14.0
[0.13.5]: https://github.com/spandx/spandx/compare/v0.13.4...v0.13.5
[0.13.4]: https://github.com/spandx/spandx/compare/v0.13.3...v0.13.4
[0.13.3]: https://github.com/spandx/spandx/compare/v0.13.2...v0.13.3
[0.13.2]: https://github.com/spandx/spandx/compare/v0.13.1...v0.13.2
[0.13.1]: https://github.com/spandx/spandx/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/spandx/spandx/compare/v0.12.3...v0.13.0
[0.12.3]: https://github.com/spandx/spandx/compare/v0.12.2...v0.12.3
[0.12.2]: https://github.com/spandx/spandx/compare/v0.12.1...v0.12.2
[0.12.1]: https://github.com/spandx/spandx/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/spandx/spandx/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/spandx/spandx/compare/v0.10.1...v0.11.0
[0.10.1]: https://github.com/spandx/spandx/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/spandx/spandx/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/spandx/spandx/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/spandx/spandx/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/spandx/spandx/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/spandx/spandx/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/spandx/spandx/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/spandx/spandx/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/spandx/spandx/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/spandx/spandx/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/spandx/spandx/compare/v0.1.7...v0.2.0
[0.1.7]: https://github.com/spandx/spandx/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/spandx/spandx/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/spandx/spandx/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/spandx/spandx/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/spandx/spandx/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/spandx/spandx/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/spandx/spandx/compare/v0.1.0...v0.1.1
