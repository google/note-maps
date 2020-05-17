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

import {RootState} from './types';
import {ActionContext} from 'vuex';

export interface Commit {
  type: string;
  payload?: any;
}

/** Supports mocking out the mutations of any Vuex store module.
 */
export class CommitMock {
  commits: Commit[];
  commit: (type: string, payload?: any) => void;

  /** Constructs a new CommitMock, ready to receive commits.
   */
  constructor() {
    this.commits = [];
    const commits = this.commits;
    this.commit = (type: string, payload?: any) => {
      commits.push({type: type, payload: payload});
    };
  }
}

export type ActionHandler<S> = (
  injectee: Partial<ActionContext<S, RootState>>,
  payload?: any
) => Promise<void>;
