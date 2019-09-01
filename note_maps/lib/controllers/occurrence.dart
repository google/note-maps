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

import 'package:flutter/widgets.dart';

import '../mobileapi/mobileapi.dart';
import 'note_map_item.dart';
import 'note_map_item_value.dart';

class OccurrenceState extends NoteMapItemState<Occurrence> {
  OccurrenceState(NoteMapItem item)
      : assert(item.noteMapKey.itemType == ItemType.OccurrenceItem),
        super(item ??
            NoteMapItem.fromItem(Item()..occurrence = Occurrence(),
                existence: NoteMapExistence.notExists));

  Occurrence get data => item.proto.occurrence;
}

class OccurrenceController extends NoteMapItemController<OccurrenceState> {
  NoteMapItemValueController _valueController;

  OccurrenceController(
    NoteMapRepository repository,
    Int64 topicMapId,
    Int64 id, {
    Int64 parentId,
  }) : super(
          repository,
          NoteMapKey(
              topicMapId: topicMapId,
              id: id,
              itemType: ItemType.OccurrenceItem),
          parentId: parentId,
        ) {
    _valueController = NoteMapItemValueController(this);
  }

  @override
  close() {
    _valueController.close();
  }

  Future<TextEditingController> get valueTextController =>
      _valueController.textController;

  @override
  OccurrenceState mapItemToState(NoteMapItem item) => OccurrenceState(item);

  @override
  ItemType get itemType => ItemType.OccurrenceItem;
}
