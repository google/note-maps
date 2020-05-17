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

import {expect} from 'chai';
import NoteMapsTextileAPI from './note-maps-textile-api';

describe('API', ()=>{
  it('is exported by index.ts', async ()=>{
    // well this wouldn't compile if it didn't, right?
    const api = new NoteMapsTextileAPI();
    const notes = await api.getNotes('some map', ['some note id']);
    expect(notes).to.be.empty;
  });
});
