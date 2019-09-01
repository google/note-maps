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

import 'package:flutter/foundation.dart';

import '../mobileapi/mobileapi.dart';
import 'name.dart';
import 'note_map_item.dart';

class TopicState extends NoteMapItemState<Topic> {
  TopicState(NoteMapItem item)
      : assert(item == null || item.noteMapKey.itemType == ItemType.TopicItem),
        super(item ??
            NoteMapItem.fromItem(Item()..topic = Topic(),
                existence: NoteMapExistence.notExists));

  Topic get data => item.proto.topic;

  String get tentativeName =>
      name != "" ? "" : "Unnamed " + (isTopicMap ? "Note Map" : "Topic");

  String get name {
    if (data == null || data.names == null || data.names.length == 0) {
      return "";
    }
    return data.names[0].value ?? "";
  }

  bool get isTopicMap =>
      data != null && data.id != 0 && data.id == data.topicMapId;
}

class TopicController extends NoteMapItemController<TopicState> {
  final ValueNotifier<NameController> _firstNameController =
      ValueNotifier<NameController>(null);

  TopicController(NoteMapRepository repository, Int64 topicMapId, Int64 id)
      : super(
            repository,
            NoteMapKey(
                topicMapId: topicMapId, id: id, itemType: ItemType.TopicItem)) {
    addListener(_updateFirstNameController);
  }

  void _updateFirstNameController() {
    if (value.data.nameIds.length == 0) {
      _firstNameController.value = null;
    } else {
      _firstNameController.value = NameController(
          repository, value.noteMapKey.topicMapId, value.data.nameIds[0]);
    }
  }

  ValueListenable<NameController> get firstNameController =>
      _firstNameController;

  @override
  List<ItemType> get canCreateChildTypes =>
      const [ItemType.OccurrenceItem, ItemType.NameItem];

  Future<Int64> createName() async {
    return await createChild(ItemType.NameItem).then((key) => key.id);
  }

  Future<Int64> createOccurrence() async {
    return await createChild(ItemType.OccurrenceItem).then((key) => key.id);
  }

  @override
  TopicState mapItemToState(NoteMapItem item) => TopicState(item);

  @override
  ItemType get itemType => ItemType.TopicItem;

  @override
  void close() {
    removeListener(_updateFirstNameController);
    super.close();
  }
}
