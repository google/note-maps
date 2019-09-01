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

import 'note_map_key.dart';
import 'store/pb/pb.pb.dart';
import 'store/pb/pb.pbenum.dart';

export 'package:fixnum/fixnum.dart' show Int64;

export 'store/pb/pb.pb.dart' show Library;
export 'store/pb/pb.pb.dart' show TopicMap;
export 'store/pb/pb.pb.dart' show Topic;
export 'store/pb/pb.pb.dart' show Name;
export 'store/pb/pb.pb.dart' show Occurrence;
export 'store/pb/pb.pb.dart' show ItemType;

class NoteMapItem {
  final NoteMapKey noteMapKey;
  final NoteMapExistence existence;
  final Item proto;

  NoteMapItem.fromKey(this.noteMapKey, {Int64 parentId})
      : existence = noteMapKey.id == 0
            ? NoteMapExistence.notExists
            : NoteMapExistence.exists,
        proto = _mapKeyToTentativeItem(noteMapKey, parentId);

  NoteMapItem.fromItem(this.proto, {this.existence = NoteMapExistence.exists})
      : assert(proto != null),
        noteMapKey = NoteMapKey.fromItem(proto);

  NoteMapItem.deleted(this.noteMapKey)
      : assert(noteMapKey != null),
        existence = NoteMapExistence.deleted,
        proto = Item();

  // Returns an Item representing something that may not exist yet, or that just
  // hasn't been fully loaded yet.
  static Item _mapKeyToTentativeItem(NoteMapKey noteMapKey, Int64 parentId) {
    switch (noteMapKey.itemType) {
      case ItemType.LibraryItem:
        return Item()..library = Library();
      case ItemType.TopicMapItem:
        return Item()
          ..topicMap = TopicMap().copyWith((x) {
            x.id = noteMapKey.topicMapId;
          });
      case ItemType.TopicItem:
        return Item()
          ..topic = Topic().copyWith((x) {
            x.topicMapId = noteMapKey.topicMapId;
            x.id = noteMapKey.id;
          });
      case ItemType.NameItem:
        return Item()
          ..name = Name().copyWith((x) {
            x.topicMapId = noteMapKey.topicMapId;
            x.id = noteMapKey.id;
            x.parentId = parentId ?? Int64(0);
          });
      case ItemType.OccurrenceItem:
        return Item()
          ..occurrence = Occurrence().copyWith((x) {
            x.topicMapId = noteMapKey.topicMapId;
            x.id = noteMapKey.id;
            x.parentId = parentId ?? Int64(0);
          });
      default:
        return Item();
    }
  }
}

enum NoteMapExistence {
  notExists,
  exists,
  deleted,
}
