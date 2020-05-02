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

import {Quill} from 'quill';

import NameFormat from './formats/name-format';
import OccurrenceFormat from './formats/occurrence-format';
import TypeFormat from './formats/type-format';
import NoteMapsQuillModule from './quill-module';

Quill.register('modules/notemaps', NoteMapsQuillModule);
Quill.register(TypeFormat);
Quill.register(OccurrenceFormat);
Quill.register(NameFormat);
