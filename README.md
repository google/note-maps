# Note Maps

[![GoDoc](https://godoc.org/github.com/google/note-maps?status.svg)](https://godoc.org/github.com/google/note-maps)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/note-maps)](https://goreportcard.com/report/github.com/google/note-maps)
[![Build Status](https://travis-ci.org/google/note-maps.svg?branch=main)](https://travis-ci.org/google/note-maps)
[![Coverage Status](https://coveralls.io/repos/github/google/note-maps/badge.svg?branch=main)](https://coveralls.io/github/google/note-maps?branch=main)

Note Maps aims to become a [personal knowledge base][] that can be used on
smartphones and laptops.

[personal knowledge base]: https://en.wikipedia.org/wiki/Personal_knowledge_base

Each note map is a collection of information about a set of topics. Any topic
can be described with a set of names, types, and miscellaneous notes that may
include definitions, timestamps, or links to images, videos, etc. Topics may be
connected to each other through associations, and any association may itself be
described as another topic. Even the role played by a topic in an association
can, itself, be described as a topic.

This model is isomorphic to the Topic Maps Data Model defined in [ISO/IEC
13250-2:2006][]. Note Maps may some day be able to import from or export to
standard Topic Map data formats like XTM ([ISO/IEC 13250-3:2013][]) and JTM
([JTM 1.1][]).

[ISO/IEC 13250-2:2006]: https://www.iso.org/standard/40017.html
[ISO/IEC 13250-3:2013]: https://www.iso.org/standard/59303.html
[JTM 1.1]: http://cerny-online.com/jtm/1.1/

Status: **Exploratory.** Note Maps is in an experimental stage and is not yet
useful for taking notes. Many design and implementation options are being
explored.

This is not an officially supported Google product.

## Development

### Install Git Hooks

This repository comes with a Git pre-commit hook in `./githooks`. Optionally,
install it: `cp ./githooks/pre-commit .git/hooks/pre-commit`.

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

1. [Install Nix][].
1. [Install direnv][].
1. Install [nix-direnv][].
1. In the root of this repository: `echo "use flake" > .envrc`

### Building

Build everything:

    nix build

The development environment configured above provides some of the standard
development tools for the programming languages used in this repository. For
example:

    go test ./...
    cargo test

### Source Code Headers

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

