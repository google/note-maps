A Dart library implementing Note Maps data types for use in editor apps

[Note Maps][] aims to support editing notes in a note map as though editing a
structured document. Integration with the best rich text editors, like QuillJS
and Zefyr, will work best if separate changes to a note map can be translated
to and from the message types of the rich text editors _as changes_. Streaming
changes in both directions between a rich text editor's internal state and the
state of a back end note map storage system will require an implementation of
some [operational transformation][] ideas. The types in this library are
designed to support such a solution.

Hoping to get something useful in a short time, these references are being
consulted:

* https://quilljs.com/guides/designing-the-delta-format/
* https://github.com/ottypes/docs
* https://github.com/google/ot-crdt-papers

[Note Maps]: https://github.com/google/note-maps
[operational transformation]: https://en.wikipedia.org/wiki/Operational_transformation

Started from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:nm_delta/nm_delta.dart';

main() {
  final noteMap = NoteMap();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][].

[issue tracker]: https://github.com/google/note-maps/issues
