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

import 'sequence_delta.dart';

class StringDelta extends SequenceDelta<int> {
  StringDelta() : super();
  StringDelta.delete(int length) : super.delete(length);
  StringDelta.insertString(String values) : super.insert(Runes(values));
  StringDelta.retain(int length) : super.retain(length);
  StringDelta.unmodifiable(Iterable<SequenceOp<int>> ops)
      : super.unmodifiable(ops);

  static Map<String, dynamic> _stringOpToJson(SequenceOp<int> op) {
    if (op.type == SequenceOpType.insert) {
      return {'i': String.fromCharCodes(op.values)};
    }
    return op.toJson();
  }

  String toBaseString() {
    return String.fromCharCodes(toBaseIterable());
  }

  @override
  List<dynamic> toJson() => map(_stringOpToJson).toList();

  @override
  StringDelta toUnmodifiable() =>
      modifiable ? StringDelta.unmodifiable(this) : this;

  void insertString(String values) {
    super.insert(Runes(values));
  }

  @override
  StringDelta apply(SequenceDelta<int> d) {
    return StringDelta.unmodifiable(super.apply(d));
  }
}
