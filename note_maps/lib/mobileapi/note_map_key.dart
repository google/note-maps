// Copyright 2019 Google LLC
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

import 'package:fixnum/fixnum.dart';

import 'store/pb/pb.pb.dart';
import 'store/pb/pb.pbenum.dart';

class NoteMapKey {
  final Int64 topicMapId;
  final Int64 id;
  final ItemType itemType;

  NoteMapKey({
    Int64 topicMapId,
    Int64 id,
    ItemType itemType,
  })  : topicMapId = topicMapId ?? Int64(0),
        id = id ?? Int64(0),
        itemType = itemType ?? ItemType.UnspecifiedItem {
    switch (itemType) {
      case ItemType.LibraryItem:
        assert(this.topicMapId == 0 && this.id == 0);
        break;
      case ItemType.TopicMapItem:
        assert(this.topicMapId == this.id);
        break;
      default:
        assert(complete || couldCreate(Int64(1)));
        break;
    }
  }

  @override
  bool operator ==(other) {
    return other is NoteMapKey &&
        topicMapId == other.topicMapId &&
        id == other.id &&
        itemType == other.itemType;
  }

  @override
  int get hashCode => topicMapId.hashCode ^ id.hashCode ^ itemType.hashCode;

  static NoteMapKey fromItem(Item item) {
    switch (item.whichSpecific()) {
      case Item_Specific.library:
        return NoteMapKey(
          topicMapId: Int64(0),
          id: Int64(0),
          itemType: ItemType.LibraryItem,
        );
      case Item_Specific.topicMap:
        return NoteMapKey(
          topicMapId: item.topicMap.id,
          id: item.topicMap.id,
          itemType: ItemType.TopicMapItem,
        );
      case Item_Specific.topic:
        return NoteMapKey(
          topicMapId: item.topic.topicMapId,
          id: item.topic.id,
          itemType: ItemType.TopicItem,
        );
      case Item_Specific.name:
        return NoteMapKey(
          topicMapId: item.name.topicMapId,
          id: item.name.id,
          itemType: ItemType.NameItem,
        );
      case Item_Specific.occurrence:
        return NoteMapKey(
          topicMapId: item.occurrence.topicMapId,
          id: item.occurrence.id,
          itemType: ItemType.OccurrenceItem,
        );
      default:
        return NoteMapKey(
          topicMapId: Int64(0),
          id: Int64(0),
          itemType: ItemType.UnspecifiedItem,
        );
    }
  }

  // Returns true if and only if this NoteMapKey unambiguously identifies a
  // single item that could possibly exist.
  bool get complete {
    switch (itemType) {
      case ItemType.LibraryItem:
        return topicMapId == 0 && id == 0;
      case ItemType.TopicMapItem:
        return topicMapId != 0 && topicMapId == id;
      case ItemType.UnspecifiedItem:
        return false;
      default:
        return topicMapId != 0 && id != 0;
    }
  }

  bool couldCreate(Int64 parentId) {
    parentId = parentId ?? Int64(0);
    switch (itemType) {
      case ItemType.LibraryItem:
        return false;
      case ItemType.TopicMapItem:
        return topicMapId == 0 && id == 0;
      case ItemType.TopicItem:
        return topicMapId != 0 && id == 0;
      case ItemType.NameItem:
        return topicMapId != 0 && id == 0 && parentId != 0;
      case ItemType.OccurrenceItem:
        return topicMapId != 0 && id == 0 && parentId != 0;
      default:
        return false;
    }
  }
}
