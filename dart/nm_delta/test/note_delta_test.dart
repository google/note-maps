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
import 'package:test/test.dart';

void main() {
  group('NoteDelta', () {
    test('toJson() includes all fields to json', () {
      final note = NoteDelta(
        value: NoteValue.insertString('test-value'),
        valueTypeID: NoteID.put('test-value-type'),
        contentIDs: NoteIDs.insert(['content-note1', 'content-note2']),
        typeIDs: NoteIDs.insert(['type-note1', 'type-note2']),
      );
      expect(note.toJson(), {
        'v': [
          {
            'i': 'test-value',
          }
        ],
        'vt': {'put': 'test-value-type'},
        'cs': [
          {
            'i': ['content-note1', 'content-note2']
          }
        ],
        'ts': [
          {
            'i': ['type-note1', 'type-note2']
          }
        ],
      });
    });

    test('toJson() handles missing fields', () {
      expect(NoteDelta().toJson(), {});
    });

    test('apply() handles null fields in base', () {
      expect(
          NoteDelta()
              .apply(NoteDelta(
                value: NoteValue.insertString('test-value'),
                valueTypeID: NoteID.put('test-value-type'),
                contentIDs: NoteIDs.insert(['content-note1', 'content-note2']),
                typeIDs: NoteIDs.insert(['type-note1', 'type-note2']),
              ))
              .toJson(),
          {
            'v': [
              {
                'i': 'test-value',
              }
            ],
            'vt': {'put': 'test-value-type'},
            'cs': [
              {
                'i': ['content-note1', 'content-note2']
              }
            ],
            'ts': [
              {
                'i': ['type-note1', 'type-note2']
              }
            ],
          });
    });

    test('apply() handles null fields in applied', () {
      expect(
          NoteDelta(
            value: NoteValue.insertString('test-value'),
            valueTypeID: NoteID.put('test-value-type'),
            contentIDs: NoteIDs.insert(['content-note1', 'content-note2']),
            typeIDs: NoteIDs.insert(['type-note1', 'type-note2']),
          ).apply(NoteDelta()).toJson(),
          {
            'v': [
              {
                'i': 'test-value',
              }
            ],
            'vt': {'put': 'test-value-type'},
            'cs': [
              {
                'i': ['content-note1', 'content-note2']
              }
            ],
            'ts': [
              {
                'i': ['type-note1', 'type-note2']
              }
            ],
          });
    });

    test('apply() applies applied', () {
      expect(
          NoteDelta(
            value: NoteValue.insertString('v1'),
            valueTypeID: NoteID.put('vt1'),
            contentIDs: NoteIDs.insert(['cs2', 'cs3']),
            typeIDs: NoteIDs.insert(['ts2', 'ts3']),
          )
              .apply(NoteDelta(
                value: NoteValue.insertString('v0'),
                valueTypeID: NoteID.put('vt0'),
                contentIDs: NoteIDs.insert(['cs0', 'cs1']),
                typeIDs: NoteIDs.insert(['ts0', 'ts1']),
              ))
              .toJson(),
          {
            'v': [
              {'i': 'v0v1'}
            ],
            'vt': {'put': 'vt0'},
            'cs': [
              {
                'i': ['cs0', 'cs1', 'cs2', 'cs3']
              }
            ],
            'ts': [
              {
                'i': ['ts0', 'ts1', 'ts2', 'ts3']
              }
            ],
          });
    });
  });
}
