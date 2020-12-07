# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2012-12-06

### Removed

- All JavaScript implementations under `js`.
- The original Flutter implementation under `note_maps`.

## [0.0.6] - 2020-12-06

### Added

- New Dart packages under `dart/...` and Flutter packages under `flutter/...`.
- GraphQL schema at `api/note.graphqls`, used [gqlgen][] to generate Go code,
  [artemis][] to generate Dart code for new Flutter package
  `flutter/nm_gql_go_link`, and some awkward glue to make them fit.
- [Zefyr][] as a subtree in `third_party/zefyr` so that custom
  attributes can be supported.
- Dart packages `dart/nm_delta` and `dart/nm_delta_notus` as an attempt to integrate with [Zefyr][]'s data models.
- Documents attempting to hash out some of the ideas here: [docs/data-model.md](docs/data-model.md)
  [docs/design.md](docs/design.md)
  [docs/like-editing-a-document.md](docs/like-editing-a-document.md)
  [docs/requirements.md](docs/requirements.md).
- [GPM][] config to help manage Dart packages.
- Makefile and some `*.mk` files for [GNU Make][] based builds.
- [Nix][] scripts under `nix`, partly managed by [Niv][], for consistent
  versions of build tools including a custom `dart` package to support builds on Darwin.

[artemis]: https://pub.dev/packages/artemis
[gqlgen]: https://github.com/99designs/gqlgen
[GNU Make]: https://www.gnu.org/software/make/
[Niv]: https://github.com/nmattia/niv
[Nix]: https://nix.dev/
[GPM]: https://pub.dev/packages/gpm

### Changed

- Applied some JavaScript security patches.
- Regenerated Go code for protocol buffers.

### Deprecated

- All JavaScript implementations under `js`.
- The original Flutter implementation under `note_maps`.

## [0.0.5] - 2020-08-03

### Changed

- Moved code related to operational transform ideas from out of `notes` into
  separate Go library `otgen`.
- Renamed Go library `notes` to `note`.
- Moved to using `go generate` for more of the build process, and moved build
  instructions from BUILD.md into README.md.

## [0.0.4] - 2020-07-25

### Changed

- Go library `notes` includes some experiments with ideas related to
  operational transforms

## [0.0.3] - 2020-07-19

### Changed

- Go library `notes`, with CLI `cmd/note-maps`, uses [Textile][] instead of
  [Genji][].

[Textile]: https://github.com/textileio/go-threads/

## [0.0.2] - 2020-07-12

### Added

- Various JavaScript attempts under `js`, centered on using https://quilljs.com
  as the main UI component for editing topic maps.
- Go library `notes`, with CLI `cmd/note-maps`, based on a re-considered data
  model and using [Genji][] for storage.

[Genji]: https://github.com/genjidb/genji

## [0.0.1] - 2019-09-18

### Added

- [docs/ux.md](docs/ux.md).
- Git pre-commit hook.
- Travis CI integration.
- Go library `kv` for local storage.
- Go library `tmaps` for working with Topic Maps, using `kv`.
- Flutter app `note_maps`, using `tmaps`.

[Unreleased]: https://github.com/google/note-maps/compare/v0.1.0...HEAD
[0.0.6]: https://github.com/google/note-maps/compare/v0.0.6...v0.1.0
[0.0.6]: https://github.com/google/note-maps/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/google/note-maps/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/google/note-maps/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/google/note-maps/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/google/note-maps/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/google/note-maps/releases/tag/v0.0.1
