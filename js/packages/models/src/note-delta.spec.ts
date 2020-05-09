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

import 'mocha';

import {expect} from 'chai';

import NoteDelta from './note-delta';
import NoteElementType from './note-element-type';
import NoteRecord from './note-record';
import ValueDelta from './value-delta';

describe('NoteDelta', () => {
  it('should apply value changes', () => {
    const d = new NoteDelta('definition-1')
        .setElementType(NoteElementType.Occurrence)
        .setNoteType('definition')
        .editValue(new ValueDelta().insert('a test.'));
    const note: NoteRecord = {
      ID: 'test',
      value: '',
      elementType: NoteElementType.Any,
      noteTypeID: '',
      childrenIDs: [],
    };
    expect(d.apply(note)).to.deep.equal({
      ID: 'test',
      value: 'a test.',
      elementType: NoteElementType.Occurrence,
      noteTypeID: 'definition',
      childrenIDs: [],
    });
  });
});
