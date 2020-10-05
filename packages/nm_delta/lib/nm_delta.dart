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

/// Represent note maps as deltas.
///
/// A delta, or diff-like, representation of a note map can be useful in the
/// implementation of any app that wants to describe a potentially complex set
/// of changes. This can be useful in representing changes made by a user, or
/// changes received from a concurrently modified branch, or peer, of the same
/// note map.
library nm_delta;

export 'src/item_op.dart';
export 'src/sequence_delta.dart';
export 'src/string_delta.dart';
export 'src/note_delta.dart';
export 'src/note_map_change.dart';
export 'src/note_map_delta.dart';
export 'src/note_map_buffer.dart';
