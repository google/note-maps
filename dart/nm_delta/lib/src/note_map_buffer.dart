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

import 'note_map_delta.dart';
import 'note_map_change.dart';

/// Translates [NoteMapDelta] objects into [NoteMapChange] objects by
/// accumulating each received delta into a base against to which the next delta
/// can be applied.
class NoteMapBuffer {
  NoteMapDelta _base;

  NoteMapBuffer() : _base = NoteMapDelta.unmodifiable({});

  /// The accumulation of all deltas applied so far.
  NoteMapDelta get base => _base;

  /// Translates [delta] into a [NoteMapChange] from [source], and updates [base].
  NoteMapChange apply(NoteMapDelta delta, String source) {
    final next = _base.apply(delta);
    final change = NoteMapChange(base: _base, delta: delta, source: source);
    _base = next;
    return change;
  }
}
