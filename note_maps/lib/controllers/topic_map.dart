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

import 'dart:async';

import '../mobileapi/mobileapi.dart';
import 'note_map_item.dart';
import 'topic.dart';

class TopicMapState extends NoteMapItemState<TopicMap> {
  TopicMapState(NoteMapItem item)
      : assert(
            item == null || item.noteMapKey.itemType == ItemType.TopicMapItem),
        super(item ??
            NoteMapItem.fromItem(Item()..topicMap = TopicMap(),
                existence: NoteMapExistence.notExists));

  TopicMap get data => item.proto.topicMap;

  String get displayName {
    if (data == null ||
        data.topic.names == null ||
        data.topic.names.length == 0 ||
        data.topic.names[0].value == "") {
      return "Unnamed Topic Map";
    }
    return data.topic.names[0].value;
  }
}

class TopicMapController extends NoteMapItemController<TopicMapState> {
  Future<TopicController> _topicController;

  TopicMapController(NoteMapRepository repository, Int64 id)
      : super(
            repository,
            NoteMapKey(
                topicMapId: id, id: id, itemType: ItemType.TopicMapItem)) {
    _topicController = completeNoteMapKey.then((noteMapKey) =>
        TopicController(repository, noteMapKey.topicMapId, noteMapKey.id));
  }

  @override
  TopicMapState mapItemToState(NoteMapItem item) => TopicMapState(item);

  @override
  ItemType get itemType => ItemType.TopicMapItem;

  Future<TopicController> get topicController => _topicController;

  @override
  List<ItemType> get canCreateChildTypes => const [ItemType.TopicItem];
}
