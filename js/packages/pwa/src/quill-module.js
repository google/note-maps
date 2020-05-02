/* Copyright 2019-2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Quill from 'quill';

function uuidv4() {
  const crypto = window.crypto || window.msCrypto;
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, (c) =>
    (
      c ^
      (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
    ).toString(16)
  );
}

export default class NoteMapsQuillModule {
  #topic;
  #topicId;

  static requiredFormats = ['note-name', 'note-occurrence', 'note-type'];

  constructor(quill, options) {
    this.quill = quill;
    this.onInput = options.onInput;
    this.topic = options.topic;
    this.quill.on('editor-change', (eventName, x, y, source) => {
      this.#topic = null;
      if (eventName == 'text-change' && source == 'user' && this.onInput) {
        this.onInput(this.topic);
      }
    });
  }

  set topic(topic) {
    if (!topic) {
      this.#topicId = null;
      this.quill.setContents({ ops: [] });
      return;
    }
    this.#topicId = topic.id;
    console.log('topic to quill', topic);
    const ops = [];
    for (const note of topic.children) {
      if (note.ntype) {
        ops.push({
          insert: note.ntype.shortName() + ': ',
          attributes: { 'note-type': note.ntype.id },
        });
      }
      ops.push({ insert: note.value });
      const vattrs = {};
      vattrs['note-' + note.etype] = note.id;
      ops.push({ insert: '\n', attributes: vattrs });
    }
    const selection = this.quill.getSelection();
    console.log('topic to quill', ops);
    this.quill.setContents({ ops: ops });
    if (selection) {
      this.quill.setSelection(selection.index, selection.length);
    }
  }

  get topic() {
    if (this.#topic) {
      return this.#topic;
    }
    if (!this.quill) {
      return;
    }
    const ops = this.quill.getContents().ops;
    const uniqueIDs = {};
    const notes = [];
    var note = {};
    var changed = false;
    for (const op of ops) {
      const blocks = [];
      if (op.insert != '\n' && op.insert.includes('\n')) {
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
            for (const etype of ['name', 'occurrence']) {
              if (block.attributes['note-' + etype]) {
                note.etype = etype;
                note.id = block.attributes['note-' + etype];
                if (note.id) {
                  break;
                }
              }
            }
          }
          if (!note.etype) {
            console.log(
              'failed to get etype for note at, converting to occurrence',
              block
            );
            note.etype = 'occurrence';
            note.id = uuidv4();
            changed = true;
          } else if (!note.id || uniqueIDs[note.id]) {
            console.log('bad id, generating a new one');
            note.id = uuidv4();
            changed = true;
          }
          uniqueIDs[note.id] = true;
          note.value = note.value || '';
          note.ntype = note.ntype || null;
          notes.push(note);
          note = {};
        } else if (block.attributes && block.attributes['note-type']) {
          var shortName = block.insert;
          if (shortName.endsWith(': ')) {
            shortName = shortName.slice(0, shortName.length - 2);
          }
          note.ntype = {};
          note.ntype.id = block.attributes['note-type'];
          note.ntype.children = [
            { id: uuidv4(), value: shortName, etype: 'name' },
          ];
          changed = true;
        } else if (block.insert) {
          note.value = (note.value || '') + block.insert;
        }
      }
    }
    this.#topic = { id: this.#topicId, children: notes };
    console.log('input', this.#topic);
    return this.#topic;
  }
}

{
  // static module initialization.
  let Block = Quill.import('blots/block');
  let Inline = Quill.import('blots/inline');

  class Note extends Block {
    static create(value) {
      let blot = super.create();
      if (typeof value == 'string') {
        blot.setAttribute('data-notemaps-id', value);
      } else {
        blot.setAttribute('data-notemaps-id', uuidv4());
      }
      return blot;
    }
    static formats(node) {
      return node.getAttribute('data-notemaps-id');
    }
  }
  Note.blotName = 'note';

  class Name extends Note {}
  Name.blotName = 'note-name';
  Name.tagName = 'H1';
  Name.className = 'note-name';
  Quill.register(Name);

  class Occurrence extends Note {}
  Occurrence.blotName = 'note-occurrence';
  Occurrence.tagName = 'p';
  Occurrence.className = 'note-occurrence';
  Quill.register(Occurrence);

  class NoteType extends Inline {
    static create(value) {
      let blot = super.create();
      if (typeof value == 'string') {
        blot.setAttribute('data-notemaps-type-id', value);
      } else {
        blot.setAttribute('data-notemaps-type-id', uuidv4());
      }
      return blot;
    }
    static formats(node) {
      return node.getAttribute('data-notemaps-type-id');
    }
  }
  NoteType.blotName = 'note-type';
  NoteType.tagName = 'dt';
  NoteType.className = 'note-type';
  Quill.register(NoteType);

  Quill.register('modules/notemaps', NoteMapsQuillModule);
}
