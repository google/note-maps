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

A handful of mostly independent implementations are mixed together in this repository. Each focuses on different parts of the problem.

1. [A mobile app](#mobile-app)
2. [A progressive web app](#progressive-web-app)
3. [A command line interface](#command-line-interface)

## Mobile App

The mobile app is a [Flutter][] front end with a UI focused on entering and
organizing notes.  Notes are stored through a [Go][] backend in a [Badger][]
database on local storage, where they can be included in system backups.

[Badger]: https://github.com/dgraph-io/badger
[Flutter]: https://flutter.dev
[Go]: https://golang.org

Code paths:

- `./kv`
- `./note-maps`
- `./tmaps`

### Screenshots

![screenshot of library page](https://github.com/google/note-maps/raw/master/docs/library.png) ![screenshot of topic page with speed-dial actinos](https://github.com/google/note-maps/raw/master/docs/fab.png) ![screenshot of topic editing page](https://github.com/google/note-maps/raw/master/docs/topic-edit.png) ![screenshot of browsing page](https://github.com/google/note-maps/raw/master/docs/browse.png)

### Roadmap to v0.1

- [x] Partial Go implementation of deserialization from CTM
- [x] Partial Go implementation of data storage for topic maps
- [x] Flutter native channel for communication with data storage
- [x] Minimal Flutter front-end that uses native channel to communicate with Go
- [x] Minimal UX research, recorded in this repository at [docs/ux.md](docs/ux.md)
- [x] Wireframe Flutter front-end with navigation
- [x] Topic maps can be created
- [x] Names can be created and edited
- [x] Notes can be created and edited
- [x] Topics added to a topic map can be reviewed
- [ ] Deletion of topic maps works correctly in the UI
- [ ] Adding, editing, and deleting names and notes works consistently
- [ ] UI includes warnings about data storage, especially deletion

### Roadmap to v0.2

- [ ] Associations and roles can be entered
- [ ] Associations involving a topic can be found from the topic page
- [ ] Browsing a topic map supports viewing all data entered in that topic map

### Roadmap beyond

- [ ] Topic maps can be exported and imported
- [ ] Data entry is reasonably easy

## Progressive Web App

Emphasis on presenting and editing a subgraph of a note map as a structured
document using QuillJS.

Code paths:

- `./js`

## Command Line Interface

Emphasis on plain text representations of notes, plausible integration with
text editor, and client-side-encrypted peer-to-peer storage.

Code paths:

- `./cmd`
- `./notes`

### Roadmap to v0.1

- [x] Use [Textilio's ThreadsDB](https://docs.textile.io/threads/) for storage.
- [ ] Support a minimal [Zettelkasten](https://zettelkasten.de/) workflow.

## Development

### Install Git Hooks

This repository comes with a Git pre-commit hook in `./githooks`. Install it:
`cp ./githooks/pre-commit .git/hooks/pre-commit`.

### Manage Git Subtrees

Add subtrees:

    git remote add third_party/zefyr https://github.com/memspace/zefyr.git
    git fetch third_party/zefyr
    git subtree add --prefix third_party/zefyr third_party/zefyr master --squash

Update subtrees:

    git fetch third_party/zefyr master
    git subtree pull --prefix third_party/zefyr third_party/zefyr master --squash

### Build the Mobile App

First, you'll need a build environment:

*   Install [Flutter](https://flutter.dev/docs/get-started/install).
*   Install [gomobile](https://golang.org/x/mobile/cmd/gomobile).

Then, generate the intermediate binaries from the `tmaps/mobileapi` package:

    go generate -tags android ./tmaps/mobileapi
    go generate -tags ios ./tmaps/mobileapi

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

This is not an officially supported Google product.
