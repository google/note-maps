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

import 'dart:convert';

import 'package:quill_delta/quill_delta.dart';
//import 'package:notus/notus.dart';

//import 'note.dart';
import 'note_map.dart';

class NotusCodec extends Codec<Delta, NoteMapDelta> {
  @override
  Converter<Delta, NoteMapDelta> get encoder => NotusToNoteMapConverter();

  @override
  Converter<NoteMapDelta, Delta> get decoder => NoteMapToNotusConverter();
}

class NotusToNoteMapConverter extends Converter<Delta, NoteMapDelta> {
  @override
  NoteMapDelta convert(Delta input) {
    final builder = NoteMapDeltaBuilder();
    /*
    final iterator = DeltaIterator(input);
    while (iterator.hasNext) {
      //final op = iterator.next();
    }
    */
    return builder.delta();
  }
}

class NoteMapToNotusConverter extends Converter<NoteMapDelta, Delta> {
  @override
  Delta convert(NoteMapDelta input) {
    final delta = Delta();
    //  ...
    return delta;
  }
}
