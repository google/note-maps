/*!
 * Copyright 2019-2020 Google LLC
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

import Vue from 'vue';

import NoteMap from './note-map.js';
import './editor.js';

import './style.css';

var app = new Vue({
  el: '#app',
  data: {
    message: 'Hello, World!',
    focus: null,
    noteMap: new NoteMap([
      { id: '1', children: ['2', '3'] },
      { id: '2', value: 'My Note Map', etype: 'name' },
      { id: '3', value: 'This is a note about my note map.' },
    ]),
  },
  created: function () {
    this.focus = this.noteMap.findById('1');
  },
  methods: {},
});
