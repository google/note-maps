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

import NoteDelta from './note-delta';
import NoteElementType from './note-element-type';
import NoteRecord from './note-record';

export interface NoteRecordLoader {
  loadNoteRecord(ID: string): NoteRecord;
}

// TODO: Obsolete NoteBuffer by migrating to NoteDelta
export interface NoteBuffer {
  ID?: string;
  value?: string;
  elementType?: NoteElementType;
  noteType?: NoteBuffer|string;
  children?: Array<NoteBuffer|string>;
}

function recordToBuffer(record: NoteRecord): NoteBuffer {
  return {
    ID: record.ID, value: record.value, elementType: record.elementType,
        noteType: record.noteTypeID, children: record.childrenIDs.map(id => id),
  }
}

export interface NoteModelParameters extends NoteBuffer {
  loader: NoteRecordLoader;
}

export type NoteOrID = NoteRecord|string;

export default class NoteModel implements NoteRecord {
  #ID: string;
  #value: string;
  #elementType: NoteElementType;
  #noteTypeID: string;
  #childrenIDs: Array<string>;
  #loader: NoteRecordLoader;

  constructor(record: NoteRecord, loader: NoteRecordLoader) {
    // TODO: throw exception if elementType is mismatched with others.
    this.#ID = record.ID;
    this.#value = record.value;
    this.#elementType = record.elementType;
    this.#noteTypeID = record.noteTypeID;
    this.#childrenIDs = [...record.childrenIDs ];
    this.#loader = loader;
  }

  get ID(): string { return this.#ID; }
  get value(): string { return this.#value; }
  get elementType(): NoteElementType { return this.#elementType; }
  get noteTypeID(): string { return this.#noteTypeID; }
  get childrenIDs(): string[] { return this.#childrenIDs; }

  get shortName(): string {
    // TODO: return the name instead
    return this.ID.slice(0, 4);
  }
  get noteType(): NoteModel {
    return new NoteModel(this.#loader.loadNoteRecord(this.#noteTypeID),
                         this.#loader);
  }
  get children(): NoteModel[] {
    const children = [];
    for (const id of this.#childrenIDs) {
      children.push(
          new NoteModel(this.#loader.loadNoteRecord(id), this.#loader));
    }
    return children;
  }
}

export class NoteMapDelta {
  noteDeltas?: Array<NoteDelta>;
}
