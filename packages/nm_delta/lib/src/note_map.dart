// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'note.dart';

class NoteMap {
  final Map<String, Note> notes;
  final String root; // ?
  NoteMap.fromNotes(Iterable<MapEntry<String, Note>> notes, String root)
      : notes = Map<String, Note>.fromEntries(notes),
        root = root;
}

class NoteMapDelta {
  final Map<String, NoteDelta> notes;
  final String root; // ?

  NoteMapDelta.fromNoteDeltas(
      Iterable<MapEntry<String, NoteDelta>> deltas, String root)
      : notes = Map.unmodifiable(Map.fromEntries(deltas)),
        root = root;

  Iterable<MapEntry<String, Note>> toNotes() sync* {
    for (var entry in notes.entries) {
      yield MapEntry<String, Note>(entry.key, entry.value.toNote());
    }
  }

  NoteMap toNoteMap() {
    return NoteMap.fromNotes(toNotes(), root);
  }
}

class NoteMapDeltaBuilder {
  final Map<String, NoteDeltaBuilder> notes;
  String root;

  NoteMapDeltaBuilder() : notes = <String, NoteDeltaBuilder>{};

  NoteDeltaBuilder note(String id) =>
      notes.putIfAbsent(id, () => NoteDeltaBuilder());

  Iterable<MapEntry<String, NoteDelta>> toNoteDeltas() sync* {
    for (var entry in notes.entries) {
      yield MapEntry<String, NoteDelta>(entry.key, entry.value.delta());
    }
  }

  NoteMapDelta delta() {
    return NoteMapDelta.fromNoteDeltas(toNoteDeltas(), root);
  }
}
