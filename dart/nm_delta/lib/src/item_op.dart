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

enum ItemOpType { put, delete, retain }

class ItemOp<T> {
  final ItemOpType type;
  final T item;

  ItemOp.put(T item)
      : type = ItemOpType.put,
        item = item;

  ItemOp.delete()
      : type = ItemOpType.delete,
        item = null;

  ItemOp.retain()
      : type = ItemOpType.retain,
        item = null;

  bool get isBase => type == ItemOpType.put;

  T toBaseItem() {
    if (!isBase) {
      throw StateError('cannot get base item from non-base item op');
    }
    return item;
  }

  Map<String, dynamic> toJson() {
    switch (type) {
      case ItemOpType.put:
        return {'put': item};
      case ItemOpType.delete:
        return {'delete': true};
      case ItemOpType.retain:
        return {};
    }
    throw StateError('item op has unrecognized type: ${type}');
  }

  ItemOp<T> apply(ItemOp<T> o) {
    if (!isBase) {
      throw StateError('cannot apply onto a non-base item op');
    }
    switch (o.type) {
      case ItemOpType.put:
        return o;
      case ItemOpType.delete:
        return ItemOp<T>.retain();
      case ItemOpType.retain:
        return this;
    }
    throw StateError('item op has unrecognized type: ${o.type}');
  }
}
