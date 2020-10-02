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

import 'dart:async';

import 'note_map_delta.dart';

enum NoteMapChangeSource {
  /// Local changes are triggered by user actions.
  local,

  /// Remote changes are changes known to be saved, whether authored locally or
  /// remotely.
  remote,
}

class NoteMapChange {
  final NoteMapDelta before;
  final NoteMapDelta change;
  final NoteMapChangeSource source;
  NoteMapChange({this.before, this.change, this.source}) {
    if (before == null) {
      throw ArgumentError.notNull('before');
    }
    if (change == null) {
      throw ArgumentError.notNull('change');
    }
    if (source == null) {
      throw ArgumentError.notNull('source');
    }
  }
}

class NoteMapBuffer {
  NoteMapDelta _local;
  final StreamController<NoteMapChange> _changes;

  NoteMapBuffer()
      : _local = NoteMapDelta.unmodifiable({}),
        _changes = StreamController<NoteMapChange>();

  NoteMapDelta get local => _local;
  Stream<NoteMapChange> get changes => _changes.stream;

  void apply(NoteMapDelta delta, NoteMapChangeSource source) {
    final next = _local.apply(delta);
    final change = NoteMapChange(before: _local, change: delta, source: source);
    _local = next;
    _changes.add(change);
  }
}
