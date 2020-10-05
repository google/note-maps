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

/// Describes an intended change to a note map.
///
/// It's possible to, say, convert this directly to JSON for some kind of
/// storage or communications protocol. However, it will probably make more
/// sense to translate simply apply it to a storage backend within a
/// transaction.
class NoteMapChange {
  /// A minimal representation of the change, as a delta.
  final NoteMapDelta delta;

  /// A context against which [delta] expresses the author's intent.
  ///
  /// This does not have to include the entire note map; it only needs to
  /// include enough information to put [delta] in context.
  final NoteMapDelta base;

  /// An application-specific or protocol-specific source identifier.
  ///
  /// Possible valid values depend on usage. An editor might only care to
  /// distinguish 'local' from 'remote' while a data synchronization peer might
  /// need a unique identifier for each peer.
  final String source;

  NoteMapChange({NoteMapDelta delta, NoteMapDelta base, this.source})
      : delta = (delta ?? NoteMapDelta(modifiable: false)).toUnmodifiable(),
        base = (base ?? NoteMapDelta(modifiable: false)).toUnmodifiable() {
    if (!base.isBase) {
      throw ArgumentError('NoteMapChange.base must be a base delta');
    }
  }
}
