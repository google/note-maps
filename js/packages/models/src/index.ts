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
import NoteModel from './note-model';

// export NoteDelta from './note-delta';
// export NoteModel from './note-model';

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
