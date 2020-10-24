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

import 'dart:collection';

enum SequenceOpType { delete, insert, retain }

class SequenceOp<T> {
  final SequenceOpType type;
  final int length;
  final List<T> values;
  SequenceOp.delete(int length)
      : type = SequenceOpType.delete,
        length = length,
        values = List<T>.empty() {
    if (length < 0) {
      throw ArgumentError('length must be non-negative');
    }
  }
  SequenceOp.insert(Iterable<T> values)
      : type = SequenceOpType.insert,
        length = values.length,
        values = List<T>.unmodifiable(values);
  SequenceOp.retain(int length)
      : type = SequenceOpType.retain,
        length = length,
        values = List<T>.empty() {
    if (length < 0) {
      throw ArgumentError('length must be non-negative');
    }
  }
  Map<String, dynamic> toJson() {
    if (type == SequenceOpType.insert) {
      return {'i': values};
    } else if (type == SequenceOpType.retain) {
      return {'r': length};
    } else if (type == SequenceOpType.delete) {
      return {'d': length};
    } else {
      throw StateError('unknown $type');
    }
  }
}

class SequenceDelta<T> extends Object with IterableMixin<SequenceOp<T>> {
  final List<SequenceOp<T>> _ops;
  final bool modifiable;

  SequenceDelta()
      : _ops = <SequenceOp<T>>[],
        modifiable = true;
  SequenceDelta.delete(int length)
      : _ops = <SequenceOp<T>>[],
        modifiable = true {
    delete(length);
  }
  SequenceDelta.insert(Iterable<T> values)
      : _ops = <SequenceOp<T>>[],
        modifiable = true {
    insert(values);
  }
  SequenceDelta.retain(int length)
      : _ops = <SequenceOp<T>>[],
        modifiable = true {
    retain(length);
  }
  SequenceDelta.unmodifiable(Iterable<SequenceOp<T>> iterable)
      : _ops = List<SequenceOp<T>>.unmodifiable(iterable),
        modifiable = false;

  bool get isBase => !_ops.any((op) => op.type != SequenceOpType.insert);

  @override
  Iterator<SequenceOp<T>> get iterator => _ops.iterator;

  Iterable<T> toBaseIterable() sync* {
    for (var op in _ops) {
      if (op.type != SequenceOpType.insert) {
        throw StateError(
            'cannot iterate a sequence delta that includes retain or delete ops.');
      }
      for (var value in op.values) {
        yield value;
      }
    }
  }

  List<dynamic> toJson() => _ops.map((op) => op.toJson()).toList();

  SequenceDelta<T> toUnmodifiable() =>
      modifiable ? SequenceDelta<T>.unmodifiable(this) : this;

  void delete(int length) {
    if (length == 0) {
      return;
    }
    _ops.add(SequenceOp<T>.delete(length));
  }

  void insert(Iterable<T> values) {
    if (values.isEmpty) {
      return;
    }
    _ops.add(SequenceOp<T>.insert(values));
  }

  void retain(int length) {
    if (length == 0) {
      return;
    }
    _ops.add(SequenceOp<T>.retain(length));
  }

  SequenceDelta<T> apply(SequenceDelta<T> d) {
    var src = toBaseIterable().toList();
    var isrc = 0;
    var result = <T>[];
    for (var op in d) {
      switch (op.type) {
        case SequenceOpType.insert:
          result.addAll(op.values);
          break;
        case SequenceOpType.retain:
          result.addAll(src.getRange(isrc, isrc + op.length));
          isrc += op.length;
          break;
        case SequenceOpType.delete:
          isrc += op.length;
          break;
        default:
          throw UnimplementedError();
      }
    }
    result.addAll(src.getRange(isrc, src.length));
    return SequenceDelta<T>.unmodifiable([SequenceOp<T>.insert(result)]);
  }
}
