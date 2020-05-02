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

import './style.css';

export enum NoteElementType {
  Any = '',
  Name = 'name',
  Variant = 'variant',
  Occurrence = 'occurrence',
  Association = 'association',
  Role = 'role',
}

export interface NoteRecord {
  readonly ID: string;
  readonly value: string;
  readonly elementType: NoteElementType;
  readonly noteTypeID: string;
  readonly childrenIDs: Array<string>;
}

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

export class NoteModel implements NoteRecord {
  #ID: string;
  #value: string;
  #elementType: NoteElementType;
  #noteTypeID: string;
  #childrenIDs: Array<string>;
  #loader: NoteRecordLoader;

  constructor({
    ID = '',
    value = '',
    elementType,
    noteType = '',
    children = [],
    loader = null
  }: NoteModelParameters) {
    // TODO: throw exception if elementType is mismatched with others.
    this.#ID = ID;
    this.#value = value;
    this.#elementType = elementType;
    this.#noteTypeID = (typeof noteType === 'string') ? noteType : noteType.ID;
    this.#childrenIDs = children.map(c => (typeof c === 'string') ? c : c.ID);
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
  get noteType(): NoteModel { return null; }
  get children(): NoteModel[] {
    const children = [];
    for (const id of this.#childrenIDs) {
      const params = recordToBuffer(this.#loader.loadNoteRecord(id)) as
                     NoteModelParameters;
      children.push(new NoteModel(params));
    }
    return children;
  }
}

export interface NoteDelta {
  readonly ID?: string;
  readonly value?: {
    [i: number]: {
      readonly retain?: number;
      readonly insert?: string;
      readonly delete?: string;
    };
  };
  readonly elementTypeDelta?: {
    readonly oldEType: NoteElementType; readonly newEType : NoteElementType;
  };
  readonly noteTypeDelta?: {readonly oldID: string; readonly newID : string;};
  readonly parentDelta?: {
    readonly oldParentID: string; readonly newParentID : string;
    // Old index in oldParent's childrenIDs array.
    readonly oldChildIndex : number;
    // New index in newParent's childrenIDs array.
    readonly newChildIndex : number;
  };
}

export interface NoteMapDelta {
  noteDeltas?: Array<NoteDelta>;
}
