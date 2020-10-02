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

import 'package:async/async.dart' show StreamQueue;
import 'package:nm_delta/nm_delta.dart';
import 'package:nm_delta_notus/nm_delta_notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

dynamic notusToJson(Delta delta) {
  return delta.toList().map((op) => op.toJson()).toList();
}

void main() {
  group('NoteMapNotusDocument', () {
    test('NoteMapNotusDocument() intial note map is empty', () {
      final bridge = NoteMapNotusDocument('test-id');
      expect(bridge.noteMap.local.toJson(), NoteMapDelta().toJson());
      expect(bridge.notusDocument.toPlainText(), '\n');
      expect(notusToJson(bridge.notusDocument.toDelta()),
          notusToJson(Delta()..insert('\n')));
    });

    test(
        'document.insert() a few words into an empty document creates a content note',
        () async {
      var nextId = 0;
      final bridge =
          NoteMapNotusDocument('test-id', newId: () => 'new${nextId++}');
      bridge.notusDocument.insert(0, 'a few words');
      await bridge.changes.first;
      expect(
          bridge.noteMap.local.toJson(),
          NoteMapDelta.from({
            'test-id': NoteDelta(contentIDs: NoteIDs.insert(['new0'])),
            'new0': NoteDelta(value: NoteValue.insertString('a few words')),
          }).toJson());
      expect(
          notusToJson(bridge.notusDocument.toDelta()),
          notusToJson(Delta()
            ..insert('a few words')
            ..insert('\n', {'nm_line_id': 'new0'})));
    });

    test('document.insert() a word in the middle of an existing note',
        () async {
      var nextId = 0;
      final bridge =
          NoteMapNotusDocument('test-id', newId: () => 'new${nextId++}');
      var changes = StreamQueue(bridge.changes);
      bridge.notusDocument.insert(0, 'a few words');
      await changes.next;
      bridge.notusDocument.insert(5, ' more');
      await changes.next;
      expect(
          bridge.noteMap.local.toJson(),
          NoteMapDelta.from({
            'test-id': NoteDelta(contentIDs: NoteIDs.insert(['new0'])),
            'new0':
                NoteDelta(value: NoteValue.insertString('a few more words')),
          }).toJson());
      expect(
          notusToJson(bridge.notusDocument.toDelta()),
          notusToJson(Delta()
            ..insert('a few more words')
            ..insert('\n', {'nm_line_id': 'new0'})));
    });
  });
}
