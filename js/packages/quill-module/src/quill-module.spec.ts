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

import NoteMapsQuillModule from '@note-maps/quill-module';
import {expect} from 'chai';
import {describe, it} from 'mocha';
import {Quill} from 'quill';

describe('NoteMapsQuillModule', () => {
  it('is registered if imported', async () => {
    const el = window.document.createElement('div');
    const quill = new Quill(el);
    expect(quill).to.not.be.null;
    const quillModule = quill.getModule('note-maps');
    expect(quillModule).to.not.be.null;
  });
});
