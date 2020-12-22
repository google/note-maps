# Note Maps

[![GoDoc](https://godoc.org/github.com/google/note-maps?status.svg)](https://godoc.org/github.com/google/note-maps)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/note-maps)](https://goreportcard.com/report/github.com/google/note-maps)
[![Build Status](https://travis-ci.org/google/note-maps.svg?branch=main)](https://travis-ci.org/google/note-maps)
[![Coverage Status](https://coveralls.io/repos/github/google/note-maps/badge.svg?branch=main)](https://coveralls.io/github/google/note-maps?branch=main)

Note Maps is a personal knowledge base intended for use on mobile devices.
Notes are structured a bit like the contents of a dictionary, or the index at
the back of a book.

Each note map is a collection of information about a set of topics. Any topic
can be described with a set of names, types, and miscellaneous notes that may
include definitions, timestamps, or links to images, videos, etc. Topics may be
connected to each other through associations, and any association may itself be
described as another topic. Even the role played by a topic in an association
can, itself, be described as a topic.

This model is isomorphic to the Topic Maps Data Model defined in [ISO/IEC
13250-2:2006][]. With Note Maps, it will be possible to for topic maps to be
imported from or exported to standard data formats including XTM ([ISO/IEC
13250-3:2013][]) and JTM ([JTM 1.1][]).

[ISO/IEC 13250-2:2006]: https://www.iso.org/standard/40017.html
[ISO/IEC 13250-3:2013]: https://www.iso.org/standard/59303.html
[JTM 1.1]: http://cerny-online.com/jtm/1.1/

Status: **Exploratory.** Note Maps is in an experimental stage and is not yet
useful for taking notes. Many design and implementation options are being
explored.

This is not an officially supported Google product.

## Mobile App

The mobile app is a [Flutter][] front end with a UI focused on entering and
organizing notes.

[Badger]: https://github.com/dgraph-io/badger
[Flutter]: https://flutter.dev
[Go]: https://golang.org

Code paths:

- `flutter/nm_app`

### Roadmap

v0.next:

- [ ] Notes are stored in a structure that might become isomorphic with topic
  maps, initially supporting at least "occurrences" and "names".
- [ ] Notes can be edited through a rich-text editor.
- [ ] Notes can be deleted.
- [ ] All existing notes can be found.
- [ ] UI includes warnings about the fragility of local data storage.

v0.next+1;

- [ ] Notes can represent "associations" with "roles".
- [ ] Notes can have one or more "types", where each type is a note.
- [ ] Notes can have "scope", where a scope is a set of notes.

## Command Line Interface

Emphasis on plain text representations of notes, plausible integration with
text editor, and client-side-encrypted peer-to-peer storage.

Code paths:

- `./cmd`
- `./notes`

### Roadmap

- [x] Use [Textilio's ThreadsDB](https://docs.textile.io/threads/) for storage.
- [ ] Support a minimal [Zettelkasten](https://zettelkasten.de/) workflow.

## Development

### Install Git Hooks

This repository comes with a Git pre-commit hook in `./githooks`. Install it:
`cp ./githooks/pre-commit .git/hooks/pre-commit`.

### Manage Git Subtrees

Vendored code goes in the `third_party` directory, preferably using `git
subtree`. For example:

    git remote add third_party/zefyr https://github.com/memspace/zefyr.git
    git fetch third_party/zefyr
    git subtree add --prefix third_party/zefyr third_party/zefyr master --squash

How to update a subtree:

    git fetch third_party/zefyr master
    git subtree pull --prefix third_party/zefyr third_party/zefyr master --squash

### Development Environment

Requirements:

*   GNU Make

Optional:

*   Flutter. To re-use an existing Flutter installation, create a `config.mk`
    file in the root of this repository and set `FLUTTER_ROOT` to the location
    of your Flutter installation. However, note the current version of Flutter
    in `FLUTTER_ROOT` will be modified by `make download`.

If you've got the time and the disk space, [Nix][] is a neat way to get a
consistent set of build tools for reproducible builds:

1. [Install Nix][].
1. Copy `nix/shell.nix` to the root of this repository.
1. In the root of this repository, run `nix-shell` to launch a shell that
   includes all build dependencies. The first time this is done, it will take a
   few minutes.

You can use [direnv][] to make this easier:

1. [install direnv][].
1. In the root of this repository, run `cp nix/envrc .envrc` and `direnv
   allow`.
1. Optionally install [nix-direnv][] to cache the `nix-shell` environment.

[Nix]: https://nixos.org/
[Install Nix]: https://nixos.org/guides/install-nix.html
[direnv]: https://direnv.net/
[install direnv]: https://direnv.net/docs/installation.html
[nix-direnv]: https://github.com/nix-community/nix-direnv
[Install Flutter]: https://flutter.dev/docs/get-started/install

### Building

Most tasks are automated through a [GNU Make][] makefile in the root of this
repository:

    gnumake format lint test build

[GNU Make]: https://www.gnu.org/software/make/

Installing and running the Flutter app is best done directly through the
`flutter` command.

    cd flutter
    cd nm_app
    flutter run

### Source Code Headers

Every file containing source code must include copyright and license
information. This includes any JS/CSS files that you might be serving out to
browsers. (This is to help well-intentioned people avoid accidental copying that
doesn't comply with the license.)

Apache header:

    Copyright 2020 Google LLC

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

