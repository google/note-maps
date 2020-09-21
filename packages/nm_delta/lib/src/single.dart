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

enum SingleOperationType { set, reset, retain }

class SingleOperation<T> {
  final SingleOperationType type;
  final T value;
  SingleOperation.set(T value)
      : type = SingleOperationType.set,
        value = value;
  SingleOperation.reset()
      : type = SingleOperationType.reset,
        value = null;
  SingleOperation.retain()
      : type = SingleOperationType.retain,
        value = null;
  T flatten() {
    if (type == SingleOperationType.retain) {
      throw StateError('cannot flatten a retain operation.');
    }
    return value;
  }
}

class SingleOperationBuilder<T> {
  SingleOperation<T> _operation;

  SingleOperationBuilder() {
    retain();
  }

  void set(T value) {
    _operation = SingleOperation<T>.set(value);
  }

  void reset() {
    _operation = SingleOperation<T>.reset();
  }

  void retain() {
    _operation = SingleOperation<T>.retain();
  }

  SingleOperation<T> operation() {
    final delta = _operation;
    retain();
    return delta;
  }
}
