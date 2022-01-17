// Copyright 2020-2021 Google LLC
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

import 'package:nm_delta/nm_delta.dart';
import 'package:nm_delta_notus/nm_delta_notus.dart';
//import 'package:nm_delta_storage/nm_delta_storage.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('QuillDocumentCodec', () {
    test('one simple content note', () {
      final quillDocument = Delta()
        ..insert('abcdef')
        ..insert('\n', {'nm_line_id': 'note0'});
      final noteMap = NoteMapDelta.from({
        '': NoteDelta(contentIDs: NoteIDs.insert(['note0'])),
        'note0': NoteDelta(value: NoteValue.insertString('abcdef')),
      });
      expect(quillDocumentCodec.decoder.convert(quillDocument).toJson(),
          noteMap.toJson());
      expect(
          quillDocumentCodec.encoder
              .convert(noteMap)
              .toList()
              .map((d) => d.toJson())
              .toList(),
          quillDocument.toList().map((d) => d.toJson()).toList());
    });
  });
}
