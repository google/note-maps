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

import 'package:notus/notus.dart';

class NoteMapLineIdAttribute extends NotusAttributeBuilder<String> {
  const NoteMapLineIdAttribute()
      : super('nm_line_id', NotusAttributeScope.line);
}

class NoteMapLineKindAttribute extends NotusAttributeBuilder<String> {
  const NoteMapLineKindAttribute()
      : super('nm_line_kind', NotusAttributeScope.line);
}

class NoteMapNotusAttribute {
  static final NoteMapLineIdAttribute lineId =
      NotusAttribute.register(NoteMapLineIdAttribute());
  static final NoteMapLineKindAttribute lineKind =
      NotusAttribute.register(NoteMapLineKindAttribute());
}
