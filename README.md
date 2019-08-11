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

The mobile app will be a [Flutter][] front end with a UI focused on entering
and organizing notes, and that uses a [GraphQL][] based protocol to communicate
with an embedded topic maps storage and query engine implemented in [Go][].

The storage engine will use an LSM based key-value store to keep topic maps in
local storage, where they may be included in system backups, and will be
responsible for serialization and deserialization of topic maps to standard
data formats.

[Flutter]: https://flutter.dev
[Go]: https://golang.org
[GraphQL]: https://graphql.org

## Status

<img alt="screenshot of library page" src="https://github.com/google/note-maps/raw/master/docs/library.png" height="300pt"/>

## Plan

1.  Develop a basic prototype to validate the entire architecture with a
    subset of the topic maps data model.

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
