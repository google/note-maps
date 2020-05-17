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

export default class NoteMap {
  constructor(notes) {
    this.notes = {};
    this.upsertMany(notes);
  }

  upsertOne(attrs) {
    const note = this.findById(attrs.id || uuidv4());
    note.update(attrs);
    return note;
  }

  upsertMany(attrss) {
    const notes = [];
    for (const attrs of attrss) {
      notes.push(this.upsertOne(attrs));
    }
    return notes;
  }

  findById(id) {
    if (typeof id != 'string') {
      throw 'only string ids are allowed for notes, got ' + typeof id;
    }
    if (!this.notes.hasOwnProperty(id)) {
      this.notes[id] = new Note(this, { id: id });
    }
    return this.notes[id];
  }
}

class Note {
  constructor(noteMap, attrs) {
    this.noteMap = noteMap;
    this.id = attrs.id || uuidv4;
    this.value = '';
    this.etype = 'occurrence';
    this.ntypeID = '';
    this.ntype = null;
    this.childIDs = [];
    this.children = [];
    this.archived = false;
    this.update(attrs);
  }
  shortName() {
    // TODO: return the name instead
    return this.id.slice(0, 4);
  }
  update(attrs) {
    console.log('updating note', this, attrs);
    if (attrs.hasOwnProperty('value')) {
      this.value = attrs.value;
    }
    if (attrs.hasOwnProperty('etype')) {
      this.etype = attrs.etype;
    }
    if (attrs.hasOwnProperty('archived')) {
      this.archived = !!attrs.archived;
    }
    if (attrs.hasOwnProperty('ntype')) {
      if (!attrs.ntype) {
        this.ntypeID = '';
        this.ntype = null;
      } else if (typeof attrs.ntype == 'string') {
        this.ntypeID = attrs.ntype;
        this.ntype = this.noteMap.findById(attrs.ntype);
      } else {
        this.ntype = this.noteMap.upsertOne(attrs.ntype);
        this.ntypeID = this.ntype.id;
      }
    }
    if (attrs.children) {
      const childIDs = [];
      var changed = false;
      for (const child of attrs.children) {
        var id;
        if (typeof child == 'string') {
          id = child;
        } else {
          id = this.noteMap.upsertOne(child).id;
        }
        const i = childIDs.push(id);
        if (i >= this.childIDs.length || childIDs[i] != this.childIDs[i]) {
          changed = true;
        }
      }
      if (changed) {
        this.childIDs = childIDs;
        const children = [];
        for (const id of this.childIDs) {
          children.push(this.noteMap.findById(id));
        }
        this.children = children;
      }
    }
    console.log('updated note', this);
  }
}
