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
  group('SequenceDelta', () {
    test('converts two inserts to a list', () {
      final delta = SequenceDelta<int>()..insert([1, 2, 3])..insert([4, 5, 6]);
      expect(delta.toBaseIterable().toList(), [1, 2, 3, 4, 5, 6]);
    });

    test('converts two inserts to json', () {
      final delta = SequenceDelta<int>()..insert([1, 2, 3])..insert([4, 5, 6]);
      expect(delta.toJson(), [
        {
          'i': [1, 2, 3]
        },
        {
          'i': [4, 5, 6]
        }
      ]);
    });

    test('apply() can insert at the beginning', () {
      final actual = SequenceDelta<int>.insert([4, 5, 6])
          .apply(SequenceDelta<int>.insert([1, 2, 3]));
      expect(actual.toJson(), [
        {
          'i': [1, 2, 3, 4, 5, 6]
        },
      ]);
    });

    test('apply() can insert in the middle', () {
      final actual = SequenceDelta<int>.insert([1, 2, 5, 6])
          .apply(SequenceDelta<int>.retain(2)..insert([3, 4]));
      expect(actual.toJson(), [
        {
          'i': [1, 2, 3, 4, 5, 6]
        },
      ]);
    });

    test('apply() can insert at the end', () {
      final actual = SequenceDelta<int>.insert([1, 2, 3])
          .apply(SequenceDelta<int>.retain(3)..insert([4, 5, 6]));
      expect(actual.toJson(), [
        {
          'i': [1, 2, 3, 4, 5, 6]
        },
      ]);
    });

    test('apply() can delete at the start', () {
      final actual = SequenceDelta<int>.insert([1, 2, 3, 4, 5, 6])
          .apply(SequenceDelta<int>.delete(3));
      expect(actual.toJson(), [
        {
          'i': [4, 5, 6]
        },
      ]);
    });

    test('apply() can delete in the middle', () {
      final actual = SequenceDelta<int>.insert([1, 2, 3, 4, 5, 6])
          .apply(SequenceDelta<int>.retain(2)..delete(2));
      expect(actual.toJson(), [
        {
          'i': [1, 2, 5, 6]
        },
      ]);
    });

    test('apply() can delete at the end', () {
      final actual = SequenceDelta<int>.insert([1, 2, 3, 4, 5, 6])
          .apply(SequenceDelta<int>.retain(4)..delete(2));
      expect(actual.toJson(), [
        {
          'i': [1, 2, 3, 4]
        },
      ]);
    });
  });

  group('StringDelta', () {
    test('converts two inserts to a string', () {
      final delta = StringDelta()
        ..insertString('hello,')
        ..insertString(' world!');
      expect(delta.toBaseString(), 'hello, world!');
    });
  });
}
