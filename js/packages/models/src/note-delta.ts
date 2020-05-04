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

import NoteElementType from './note-element-type';
import NoteRecord from './note-record';
import ValueDelta from './value-delta';

export default class NoteDelta {
  #valueDelta?: ValueDelta;
  #elementType?: NoteElementType;
  #noteTypeID?: string;

  constructor(readonly ID: string) {}

  editValue(d: ValueDelta): NoteDelta {
    this.#valueDelta =
        (this.#valueDelta === void 0) ? d : this.#valueDelta.compose(d);
    return this;
  }
  setElementType(t: NoteElementType): NoteDelta {
    this.#elementType = t;
    return this;
  }
  setNoteType(t: string): NoteDelta {
    this.#noteTypeID = t;
    return this;
  }

  apply(prev: NoteRecord): NoteRecord {
    return {
      ID : prev.ID,
      value : (this.#valueDelta === void 0)
                  ? prev.value
                  : this.#valueDelta.apply(prev.value),
      elementType : (this.#elementType === void 0) ? prev.elementType
                                                   : this.#elementType,
      noteTypeID : (this.#noteTypeID === void 0) ? prev.noteTypeID
                                                 : this.#noteTypeID,
      childrenIDs : prev.childrenIDs,
    };
  }
}
