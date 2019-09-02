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

class NoteMapItemValueController {
  final NoteMapItemController itemController;
  Future<TextEditingController> _futureTextController;
  TextEditingController _textController;

  NoteMapItemValueController(this.itemController) {
    _futureTextController = itemController.completeNoteMapKey
        .then((noteMapKey) =>
            _textController = TextEditingController(text: _currentValue())
              ..addListener(_textControllerChanged))
        .catchError((_) => null);
  }

  String _currentValue() {
    var item = itemController.value?.item;
    switch (item?.noteMapKey?.itemType) {
      case ItemType.NameItem:
        return item.proto.name.value;
      case ItemType.OccurrenceItem:
        return item.proto.occurrence.value;
      default:
        return "";
    }
  }

  void close() {
    Future.sync(() => _futureTextController)
        .then((controller) => controller.removeListener(_textControllerChanged))
        .catchError((error) {});
  }

  void _textControllerChanged() {
    if (itemController.value.noteMapKey.complete) {
      itemController.repository
          .updateValue(itemController.value.noteMapKey, _textController.text);
    }
  }

  Future<TextEditingController> get textController => _futureTextController;
}
