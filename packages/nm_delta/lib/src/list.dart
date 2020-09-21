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

enum ListOperationType { delete, insert, retain }

class ListOperation<T> {
  final ListOperationType type;
  final int length;
  final List<T> values;
  ListOperation.delete(int length)
      : type = ListOperationType.delete,
        length = length,
        values = List<T>.empty();
  ListOperation.insert(Iterable<T> values)
      : type = ListOperationType.insert,
        length = values.length,
        values = List<T>.unmodifiable(values);
  ListOperation.retain(int length)
      : type = ListOperationType.retain,
        length = length,
        values = List<T>.empty();
}

class ListDelta<T> {
  final List<ListOperation<T>> operations;
  ListDelta() : operations = List<ListOperation<T>>.empty();
  ListDelta.fromOperations(Iterable<ListOperation<T>> operations)
      : operations = List<ListOperation<T>>.unmodifiable(operations);
  List<T> flatten() {
    var result = <T>[];
    for (var op in operations) {
      if (op.type != ListOperationType.insert) {
        throw StateError(
            'cannot flatten a delta that includes retain or delete operations.');
      }
      result.addAll(op.values);
    }
    return result;
  }
}

class ListDeltaBuilder<T> {
  List<ListOperation<T>> operations;
  ListDeltaBuilder() : operations = [];
  void delete(int length) {
    operations.add(ListOperation<T>.delete(length));
  }

  void insert(Iterable<T> values) {
    operations.add(ListOperation<T>.insert(values));
  }

  void retain(int length) {
    operations.add(ListOperation<T>.retain(length));
  }

  ListDelta<T> delta() {
    final delta = ListDelta<T>.fromOperations(operations);
    operations = [];
    return delta;
  }
}
