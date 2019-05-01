# Note Maps

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

The mobile app will be a [Flutter][] client that uses [GraphQL][] over HTTP to
communicate with an embedded web server implemented in [Go][]. The embedded
server will bind to a random port on `localhost`, will serve HTTPS using a
unique self-signed certificate, and will provide the URL along with a randomly
generated authentication token to the mobile app.

The server will use an LSM based key-value store to keep topic maps in local
storage, and will be responsible for serialization and deserialization of topic
maps to standard data formats.

[Flutter]: https://flutter.dev
[Go]: https://golang.org
[GraphQL]: https://graphql.org

## Plan

1.  Develop a basic prototype to validate the entire architecture with a
    simplified data model: only topics and names, no occurrences or
    associations.

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
