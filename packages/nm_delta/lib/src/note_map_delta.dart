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

import 'dart:collection';

import 'note_delta.dart';

class NoteMapDelta {
  final Map<String, NoteDelta> _notes;
  final bool _modifiable;

  NoteMapDelta()
      : _notes = <String, NoteDelta>{},
        _modifiable = true;

  NoteMapDelta.from(Map<String, NoteDelta> deltas)
      : _notes = Map<String, NoteDelta>.from(deltas),
        _modifiable = true;

  NoteMapDelta.unmodifiable(Map<String, NoteDelta> deltas)
      : _notes = UnmodifiableMapView<String, NoteDelta>(Map.fromEntries(
            deltas.entries.map((entry) => MapEntry<String, NoteDelta>(
                entry.key, entry.value.toUnmodifiable())))),
        _modifiable = false;

  Iterable<String> get ids => _notes.keys;

  bool get isBase => !_notes.values.any((v) => !v.isBase);

  NoteDelta operator [](String id) => _notes[id];

  Iterable<MapEntry<String, NoteDelta>> get entries => _notes.entries;

  Map<String, dynamic> toJson() {
    return Map.fromEntries(_notes.entries.map(
        (entry) => MapEntry<String, dynamic>(entry.key, entry.value.toJson())));
  }

  NoteMapDelta toUnmodifiable() =>
      _modifiable ? NoteMapDelta.unmodifiable(_notes) : this;

  NoteMapDelta apply(NoteMapDelta d) {
    final keys = Set.of(_notes.keys.followedBy(d._notes.keys));
    return NoteMapDelta.unmodifiable(
        Map<String, NoteDelta>.fromEntries(keys.map((id) {
      final base = this[id] ?? NoteDelta();
      final applied = d[id] ?? NoteDelta();
      return MapEntry<String, NoteDelta>(id, base.apply(applied));
    })));
  }
}
