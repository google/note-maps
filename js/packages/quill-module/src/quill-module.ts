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

import {
  NoteBuffer,
  NoteElementType,
  NoteMapDelta,
  NoteModel,
} from '@note-maps/models';
import Quill from 'quill';
import Delta from 'quill-delta';

import NoteMapsQuillModuleOptions from './quill-module-options';

export default class NoteMapsQuillModule {
  #topic: NoteModel;
  #topicID: string;
  #quill: Quill;
  #onInput: { (delta: NoteMapDelta): void };

  static requiredFormats = ['note-name', 'note-occurrence', 'note-type'];

  constructor(quill: Quill, options: NoteMapsQuillModuleOptions = {}) {
    this.#quill = quill;
    this.#onInput = options.onInput;
    this.#topic = options.topic;
    this.#quill.on('editor-change', (eventName, x, y, source) => {
      this.#topic = null;
      if (eventName == 'text-change' && source == 'user' && this.#onInput) {
        this.#onInput(/* this.#topic */ {});
      }
    });
  }

  set topic(topic: NoteModel) {
    if (!topic) {
      this.#topic = null;
      this.#topicID = null;
      this.#quill.setContents(new Delta([]));
      return;
    }
    this.#topicID = topic.ID;
    console.log('topic to quill', topic);
    const delta = new Delta();
    const ops = delta.ops;
    for (const note of topic.children) {
      if (note.noteType) {
        ops.push({
          insert: note.noteType.shortName + ': ',
          attributes: {'note-type': note.noteType.ID},
        });
      }
      ops.push({insert: note.value});
      const vattrs = {};
      vattrs['note-' + note.elementType] = note.ID;
      ops.push({insert: '\n', attributes: vattrs});
    }
    const selection = this.#quill.getSelection();
    console.log('topic to quill', ops);
    this.#quill.setContents(delta);
    if (selection) {
      this.#quill.setSelection(selection.index, selection.length);
    }
  }

  get topic() {
    if (this.#topic) {
      return this.#topic;
    }
    if (!this.#quill) {
      return;
    }
    const ops = this.#quill.getContents().ops;
    const uniqueIDs = {};
    const notes: NoteBuffer[] = [];
    let note: NoteBuffer = {};
    for (const op of ops) {
      const blocks = [];
      if (
        typeof op.insert === 'string' &&
        op.insert != '\n' &&
        op.insert.includes('\n')
      ) {
        for (const line of op.insert.split('\n')) {
          blocks.push({
            insert: line,
            attributes: op.attributes,
          });
          blocks.push({
            insert: '\n',
            attributes: op.attributes,
          });
        }
        if (!op.attributes) {
          blocks.length -= 1;
        }
      } else {
        blocks.push(op);
      }
      for (const block of blocks) {
        if (block.insert == '\n') {
          if (block.attributes) {
            for (const etype of [
              NoteElementType.Name,
              NoteElementType.Occurrence,
            ]) {
              if (block.attributes['note-' + etype]) {
                note.elementType = etype;
                note.ID = block.attributes['note-' + etype];
                if (note.ID) {
                  break;
                }
              }
            }
          }
          if (!note.elementType) {
            console.log(
                'failed to get elementType for note at, converting to ' +
                'occurrence',
                block,
            );
            note.elementType = NoteElementType.Occurrence;
            note.ID = '';
          } else if (!note.ID || uniqueIDs[note.ID]) {
            console.log('bad ID, generating a new one');
            note.ID = '';
          }
          uniqueIDs[note.ID] = true;
          note.value = note.value || '';
          note.noteType = note.noteType || null;
          notes.push(note);
          note = {};
        } else if (block.attributes && block.attributes['note-type']) {
          let shortName = block.insert;
          if (shortName.endsWith(': ')) {
            shortName = shortName.slice(0, shortName.length - 2);
          }
          note.noteType = {};
          note.noteType.ID = block.attributes['note-type'];
          note.noteType.children = [
            {ID: '', value: shortName, elementType: NoteElementType.Name},
          ];
        } else if (block.insert) {
          note.value = (note.value || '') + block.insert;
        }
      }
    }
    // TODO: this used to be the way the editor kept track of the topic it was
    // editing.
    // this.#topic = new NoteModel({ID : this.#topicID, children : notes});
    console.log('input', this.#topic);
    return this.#topic;
  }
}
