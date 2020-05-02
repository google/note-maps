# Note Maps JavaScript

Note maps can be treated like a set of structured documents, where topic names
become headings, and where occurrences and associations become list items under
those headings.  If the type of each occurrence and role are included, and the
formatted text can be edited to apply corresponding updates to the same names,
occurrences, and associations, then most people who have ever used a word
processor will be able to easily develop their own note maps.

In this implementation,

*   Every topic, name, variant, occurrence, role, and association is just a
    "Note".
*   Each name, variant, occurrence, role, or association that is reified by a
    topic is represented together with that topic as a single "Note".

In an eventual functional implementation,

*   Each child (name, occurrence, ~role) of a selected topic can be mapped to
    and from an HTML element that represents one (`display: block`) line or
    paragraph of text.
*   These lines and paragraphs can be viewed and edited as a coherent document.
*   The mapping from rich text edits to note updates is consistent, and
    generally simple.
*   All valid updates to the notes are possible through edits to the rich text
    representation of those notes. Exceptions are rare, like deleting empty
    topics, and will be supported in other ways.

For the time being, this will be implemented against in-memory and/or
device-local storage.

*   To be useful, note maps must be stored much more reliably.
*   To be well used, note maps must be private by default.
*   To be widely uesful, reliable, private storage must be nearly effortless.
*   Personally, I want to be able to work on my note maps while offline.

Some options:

*   Roll our own periodic encrypted export to a generic storage system.
*   Roll our own encrypted writes to an offline-first storage system.
    *   https://github.com/orbitdb/orbit-db
    *   https://github.com/amark/gun
*   Use an existing storage system that is encrypted and offline-first.
    *   https://github.com/textileio/js-threads (technically possible, but not
        as straightforward as it looks.)

## Development

Get started with `git clone https://github.com/google/note-maps && cd
note-maps/js && yarn`.

This project uses [yarn workspaces][] so that dependencies of all
`./packages/*/package.json` are installed once in `./node_modules/`. 

[yarn workspaces]: https://classic.yarnpkg.com/en/docs/workspaces/

## Source Code Headers

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
