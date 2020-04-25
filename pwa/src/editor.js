/* Copyright 2019 Google LLC
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
import Vue from 'vue';

import NoteMapsQuillModule from './quill-module.js';

import './style.css';

Vue.component('editor', {
  model: {
    prop: 'topic',
    event: 'input',
  },
  props: ['topic'],
  template: `
    <div v-if='topic'>
      <div class="note-toolbar" v-bind:id='"toolbar" + topic.id'>
        <button class='ql-note-name'>N</button>
        <button class='ql-note-type'>T</button>
        <button class='ql-bold'></button>
        <button class='ql-italic'></button>
        <button class='ql-underline'></button>
      </div>
      <div class="note-editor"></div>
    </div>
  `,
  mounted: function () {
    this.$nextTick(() => {
      this.quill = new Quill(this.$el.querySelector('.note-editor'), {
        formats: NoteMapsQuillModule.requiredFormats,
        modules: {
          toolbar: this.$el.querySelector('.note-toolbar'),
          notemaps: {
            onInput: (topic) => {
              this.quillToTopic(topic);
            },
          },
        },
      });
      this.noteMapsModule = this.quill.getModule('notemaps');
      if (this.topic) {
        this.topicToQuill();
      }
    });
  },
  methods: {
    topicToQuill: function () {
      this.noteMapsModule.topic = this.topic;
    },
    quillToTopic: function (topic) {
      console.log('input', topic);
      this.topic.update(topic);
      this.$nextTick(() => {
        this.topicToQuill();
      });
    },
  },
});
