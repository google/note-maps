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

### With Nix

Dependencies:

*  Use Linux or MacOS.
*  [Nix][].

Test or build following the instructions for "without Nix", but run each
command through `nix-shell`. For example, `nix-shell --run "cd flutter/nm_app;
flutter run"`.

To build a final release,

1. `nix-shell --run "make -e download"`
1. `nix-build -A web` (or `-A appbundle`, `-A ios`, etc.)
1. Copy outputs from `./result`.

### Without Nix

Dependencies:

*   Flutter
*   [GNU Make][] (note for OSX: not `brew install gnumake`, not `brew install
    make`)

[Nix]: https://nixos.org/guides/install-nix.html
[GNU Make]: https://www.gnu.org/software/make/

There are a few useful make targets. For starters, this should cover most cases
during development: `make -e download format lint test`.

You can run the app from its directory, `./flutter/nm_app`, as you would any
Flutter app: `cd flutter/nm_app ; flutter run`.

You can build final releases this way too, but they may not match the
reproducible build outputs we (hope to) get by using Nix.  This should work if
you've already done a `make -e download`:

1. `make -e build FLUTTER_BUILD="web appbundle ios"` (or just
   `FLUTTER_BUILD="web"`, etc.)
1. Copy outputs from `./out`

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

