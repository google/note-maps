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
import {actions} from './actions';
import {NoteRecord} from '@note-maps/models';
import {NoteMapState} from './types';
import {API} from '../types';
import {ActionHandler, CommitMock} from '../actions.spec';

const api: API = {
  async getNotes(
      noteMapID: string,
      noteIDs: string[],
  ): Promise<Partial<NoteRecord>[]> {
    if (noteIDs.indexOf('missing') >= 0) {
      throw Error('nope');
    }
    return noteIDs.map(
        (id) => ({ID: id, value: 'value of ' + id} as Partial<NoteRecord>),
    );
  },
};

const fetchNotes = actions({api}).fetchNotes as ActionHandler<NoteMapState>;

describe('NoteMap actions', () => {
  describe('fetchNotes', () => {
    it('handles errors', async () => {
      const {commits, commit} = new CommitMock();
      await fetchNotes({commit}, {noteIDs: ['missing']});
      expect(commits).to.deep.equal([
        {type: 'notesLoading', payload: {noteIDs: ['missing']}},
        {
          type: 'notesLoadError',
          payload: {noteIDs: ['missing']},
        },
      ]);
    });

    it('fetches notes', async () => {
      const {commits, commit} = new CommitMock();
      await fetchNotes({commit}, {noteIDs: ['abc', '234']});
      expect(commits).to.deep.equal([
        {type: 'notesLoading', payload: {noteIDs: ['abc', '234']}},
        {
          type: 'notesLoaded',
          payload: {
            notes: [
              {ID: 'abc', value: 'value of abc'} as Partial<NoteRecord>,
              {ID: '234', value: 'value of 234'} as Partial<NoteRecord>,
            ],
          },
        },
      ]);
    });
  });
});
