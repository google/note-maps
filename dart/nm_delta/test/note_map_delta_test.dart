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
  group('NoteMapDelta', () {
    test('toJson() reports some basic note deltas', () {
      var noteMap = NoteMapDelta.from({
        'root': NoteDelta(contentIDs: NoteIDs.insert(['name0'])),
        'name0': NoteDelta(
            value: NoteValue.insertString('Root Note'),
            typeIDs: NoteIDs.insert(['name'])),
      });
      expect(noteMap.toJson(), {
        'root': {
          'cs': [
            {
              'i': ['name0']
            }
          ],
        },
        'name0': {
          'v': [
            {'i': 'Root Note'}
          ],
          'ts': [
            {
              'i': ['name']
            }
          ],
        },
      });
    });

    test('toJson() reports some basic note deltas', () {
      var noteMap = NoteMapDelta.from({
        'root': NoteDelta(contentIDs: NoteIDs.insert(['name0'])),
        'name0': NoteDelta(
            value: NoteValue.insertString('Root Note'),
            typeIDs: NoteIDs.insert(['name'])),
      });
      expect(noteMap.toJson(), {
        'root': {
          'cs': [
            {
              'i': ['name0']
            }
          ],
        },
        'name0': {
          'v': [
            {'i': 'Root Note'}
          ],
          'ts': [
            {
              'i': ['name']
            }
          ],
        },
      });
    });

    test('apply() applies overlapping note deltas and copies the rest', () {
      expect(
          NoteMapDelta.from({
            'left': NoteDelta(value: NoteValue.insertString('left')),
            'both': NoteDelta(value: NoteValue.insertString('left')),
          })
              .apply(NoteMapDelta.from({
                'both': NoteDelta(
                    value: NoteValue.retain(4)..insertString('right')),
                'right': NoteDelta(value: NoteValue.insertString('right')),
              }))
              .toJson(),
          {
            'left': {
              'v': [
                {'i': 'left'}
              ]
            },
            'both': {
              'v': [
                {'i': 'leftright'}
              ]
            },
            'right': {
              'v': [
                {'i': 'right'}
              ]
            },
          });
    });
  });
}
