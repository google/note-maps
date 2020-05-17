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

import Quill from 'quill';

const Inline = Quill.import('blots/inline');

export default class TypeFormat extends Inline {
  public static blotName = 'note-type';
  public static tagName = 'dt';
  public static className = 'note-type';
  static create(value: any) {
    const blot = super.create();
    if (typeof value === 'string') {
      blot.setAttribute('data-notemaps-type-id', value);
    } else {
      blot.setAttribute('data-notemaps-type-id', '');
    }
    return blot;
  }

  static formats(node: any) {
    return node.getAttribute('data-notemaps-type-id');
  }
}
