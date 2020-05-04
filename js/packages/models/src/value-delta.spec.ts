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

import 'mocha';

import {expect} from 'chai';

import ValueDelta from './value-delta';

describe('ValueDelta', () => {
  describe('with simple direct ops should apply', () => {
    it('insertion', () => {
      expect(new ValueDelta().insert('abc').apply('def')).to.equal('abcdef');
    });
    it('removal', () => {
      expect(new ValueDelta().remove(3).apply('xyzabc')).to.equal('abc');
    });
    it('retain before insertion', () => {
      expect(new ValueDelta().retain(3).insert('def').apply('abcghi'))
          .to.equal('abcdefghi');
    });
    it('retain before removal', () => {
      expect(new ValueDelta().retain(3).remove(3).apply('abcxyzghi'))
          .to.equal('abcghi');
    });
  });
  describe('when composed should apply', () => {
    it('insert before insertion', () => {
      expect(new ValueDelta()
                 .insert('def')
                 .compose(new ValueDelta().insert('abc'))
                 .apply('ghi'))
          .to.equal('abcdefghi');
    });
    it('retain and insert after insertion', () => {
      expect(new ValueDelta()
                 .insert('abc')
                 .compose(new ValueDelta().retain(3).insert('def'))
                 .apply('ghi'))
          .to.equal('abcdefghi');
    });
    it('retain and remove after insertion', () => {
      expect(new ValueDelta()
                 .insert('abc')
                 .compose(new ValueDelta().retain(3).remove(3))
                 .apply('xyz'))
          .to.equal('abc');
    });
  });
});
