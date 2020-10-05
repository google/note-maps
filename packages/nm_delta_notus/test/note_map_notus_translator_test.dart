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

import 'package:nm_delta/nm_delta.dart';
import 'package:nm_delta_notus/nm_delta_notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';
import 'package:test/test.dart';

dynamic notusToJson(Delta delta) {
  return delta.toList().map((op) => op.toJson()).toList();
}

void main() {
  group('NoteMapNotusTranslator', () {
    NotusDocument document;
    NoteMapNotusTranslator translator;
    Delta notusBefore;

    setUp(() {
      document = NotusDocument();
      notusBefore = document.toDelta();
      var nextId = 0;
      translator =
          NoteMapNotusTranslator('test-id', newId: () => 'new${nextId++}');
    });

    NoteMapNotusDelta translate(Delta delta,
        {ChangeSource source = ChangeSource.local}) {
      final change =
          translator.onNotusChange(NotusChange(notusBefore, delta, source));
      notusBefore = document.toDelta();
      return change;
    }

    test(
        'document.insert() a few words into an empty document creates a content note',
        () async {
      final actual = translate(document.insert(0, 'a few words'));
      expect(
          actual.noteMap.toJson(),
          NoteMapDelta.from({
            'test-id': NoteDelta(contentIDs: NoteIDs.insert(['new0'])),
            'new0': NoteDelta(value: NoteValue.insertString('a few words')),
          }).toJson());
      expect(notusToJson(actual.notus),
          notusToJson(Delta()..retain(11)..retain(1, {'nm_line_id': 'new0'})));
      document.compose(actual.notus, ChangeSource.local);
      expect(
          notusToJson(document.toDelta()),
          notusToJson(Delta()
            ..insert('a few words')
            ..insert('\n', {'nm_line_id': 'new0'})));
    });

    test('document.insert() a word in the middle of an existing note',
        () async {
      document.compose(translate(document.insert(0, 'a few words')).notus,
          ChangeSource.local);
      notusBefore = document.toDelta();
      final actual = translate(document.insert(5, ' more'));
      expect(
          notusToJson(document.toDelta()),
          notusToJson(Delta()
            ..insert('a few more words')
            ..insert('\n', {'nm_line_id': 'new0'})));
      expect(
          actual.noteMap.toJson(),
          NoteMapDelta.from({
            'new0':
                NoteDelta(value: NoteValue.retain(5)..insertString(' more')),
          }).toJson());
    });
  });
}
