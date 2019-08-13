# Note Maps

[![GoDoc](https://godoc.org/github.com/google/note-maps?status.svg)](https://godoc.org/github.com/google/note-maps)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/note-maps)](https://goreportcard.com/report/github.com/google/note-maps)
[![Build Status](https://travis-ci.org/google/note-maps.svg?branch=master)](https://travis-ci.org/google/note-maps)
[![Coverage Status](https://coveralls.io/repos/github/google/note-maps/badge.svg?branch=master)](https://coveralls.io/github/google/note-maps?branch=master)

Note Maps is a personal knowledge base designed for use on mobile devices. The
interface is modeled after the pages of a dictionary, or the index at the back
of a book.

Each note map is a collection of information about a set of topics. Any topic
can be described with a set of names, types, and miscellaneous notes that may
include definitions, timestamps, or links to other kinds of media. Topics may be
connected to each other through associations, and any association may itself be
described as another topic. Even the role played by a topic in an association
can, itself, be described as a topic.

This model is isomorphic to the Topic Maps Data Model defined in
[ISO/IEC 13250-2:2006][]. With Note Maps, topic maps can be imported from or
exported to standard data formats including XTM ([ISO/IEC 13250-3:2013][]) and
JTM ([JTM 1.1][]).

[ISO/IEC 13250-2:2006]: https://www.iso.org/standard/40017.html
[ISO/IEC 13250-3:2013]: https://www.iso.org/standard/59303.html
[JTM 1.1]: http://cerny-online.com/jtm/1.1/

## Architecture Overview

The mobile app is a [Flutter][] front end with a UI focused on entering and
organizing notes.  Notes are stored through a [Go][] backend in a [Badger][]
database on local storage, where they can be included in system backups.

[Badger]: https://github.com/dgraph-io/badger
[Flutter]: https://flutter.dev
[Go]: https://golang.org

## Screenshots

![screenshot of library page](https://github.com/google/note-maps/raw/master/docs/library.png) ![screenshot of topic page](https://github.com/google/note-maps/raw/master/docs/topic.png) ![screenshot of topic rename dialog](https://github.com/google/note-maps/raw/master/docs/topic-rename.png) ![screenshot of topic edit note dialog](https://github.com/google/note-maps/raw/master/docs/topic-edit-note.png) ![screenshot of topic role menu](https://github.com/google/note-maps/raw/master/docs/topic-role-menu.png)

## Plan

- [x] Partial Go implementation of deserialization from CTM
- [x] Partial Go implementation of data storage for topic maps
- [x] Flutter native channel for communication with data storage
- [x] Minimal Flutter front-end that uses native channel to communicate with Go
- [ ] Minimal UX research, recorded in this repository
- [x] Wireframe Flutter front-end with navigation
- [ ] Topic maps can be created
- [ ] Names can be created and edited
- [ ] Notes can be created and edited
- [ ] ...

## Source Code Headers

Every file containing source code must include copyright and license
information. This includes any JS/CSS files that you might be serving out to
browsers. (This is to help well-intentioned people avoid accidental copying that
doesn't comply with the license.)

Apache header:

    Copyright 2019 Google LLC

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
