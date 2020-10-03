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

import 'package:nm_delta/nm_delta.dart';
import 'package:test/test.dart';

void main() {
  group('ItemOp', () {
    test('toBaseItem() returns the value given through put()', () {
      final op = ItemOp<String>.put('hello');
      expect(op.toBaseItem(), 'hello');
    });

    test('toJson() works when a value is given through put()', () {
      final op = ItemOp<String>.put('hello');
      expect(op.toJson(), {'put': 'hello'});
    });

    test('apply() can replace a value.', () {
      final actual = ItemOp<int>.put(1).apply(ItemOp<int>.put(2));
      expect(actual.toJson(), {'put': 2});
    });

    test('apply() can clear a value.', () {
      final actual = ItemOp<int>.put(1).apply(ItemOp<int>.delete());
      expect(actual.toJson(), {});
    });

    test('apply() can retain a value.', () {
      final actual = ItemOp<int>.put(1).apply(ItemOp<int>.retain());
      expect(actual.toJson(), {'put': 1});
    });
  });
}
