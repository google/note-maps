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

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'mobileapi.dart';
import 'store/pb/pb.pb.dart';

abstract class NoteMapItemState<T> {
  final NoteMapItem item;

  NoteMapItemState(this.item) : assert(item != null);

  NoteMapKey get noteMapKey => item.noteMapKey;

  NoteMapExistence get existence => item.existence;

  T get data;
}

class LibraryState extends NoteMapItemState<Library> {
  LibraryState(NoteMapItem item)
      : assert(
            item == null || item.noteMapKey.itemType == ItemType.LibraryItem),
        super(item ??
            NoteMapItem.fromItem(Item()..library = Library(),
                existence: NoteMapExistence.notExists));

  Library get data => item.proto.library;
}

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

class NameState extends NoteMapItemState<Name> {
  NameState(NoteMapItem item)
      : assert(item == null || item.noteMapKey.itemType == ItemType.NameItem),
        super(item ??
            NoteMapItem.fromItem(Item()..name = Name(),
                existence: NoteMapExistence.notExists));

  Name get data => item.proto.name;
}

class OccurrenceState extends NoteMapItemState<Occurrence> {
  OccurrenceState(NoteMapItem item)
      : assert(item.noteMapKey.itemType == ItemType.OccurrenceItem),
        super(item ??
            NoteMapItem.fromItem(Item()..occurrence = Occurrence(),
                existence: NoteMapExistence.notExists));

  Occurrence get data => item.proto.occurrence;
}

abstract class LibraryEvent {}

class LibraryReloadEvent extends LibraryEvent {}

abstract class NoteMapItemController<S extends NoteMapItemState>
    extends ValueListenable<S> {
  final NoteMapRepository repository;
  ValueNotifier<S> _state;
  StreamSubscription<NoteMapItem> _repositorySubscription;
  final Completer<NoteMapKey> _completeKey = Completer<NoteMapKey>();

  // Creates a new NoteMapListenable that will watch repository for changes to
  // the item identified by key.
  //
  // If the noteMapKey is not complete, but contains enough information that
  // together with the optional parentId argument a new item could be created,
  // then that creation will be initiated by this constructor.
  NoteMapItemController(this.repository, NoteMapKey noteMapKey,
      {Int64 parentId})
      : assert(noteMapKey.complete || noteMapKey.couldCreate(parentId)) {
    if (noteMapKey.complete) {
      // We have to initialize _state before subscribing to repository.items,
      // and we'd like to initialize state from the cache if possible.
      var cached = repository.fromCache(noteMapKey);
      _state = ValueNotifier<S>(
          mapItemToState(cached ?? NoteMapItem.fromKey(noteMapKey)));
      _subscribe();
      // Finally, if there was nothing in the cache, request a reload for this
      // item.
      if (cached == null) {
        repository.reload(noteMapKey);
      }
      _completeKey.complete(noteMapKey);
    } else {
      // We know there's nothing in the cache for the key as it's incomplete.
      // Instead, we initialize _state with a default value before beginning the
      // async work of creating an item.
      _state =
          ValueNotifier<S>(mapItemToState(NoteMapItem.fromKey(noteMapKey)));
      repository
          .create(
              noteMapKey.topicMapId, parentId ?? Int64(0), noteMapKey.itemType)
          .then((item) {
        _state.value = mapItemToState(item);
        _subscribe();
        _completeKey.complete(_state.value.noteMapKey);
      }).catchError((error) {
        // TODO: map error to item, then use mapItemToState.
        _completeKey.completeError(error);
      });
    }
  }

  void _subscribe() {
    assert(_repositorySubscription == null);
    _repositorySubscription = repository.items.listen((item) {
      if (item != null && item.noteMapKey == value.noteMapKey) {
        _state.value = mapItemToState(item);
      }
    });
  }

  // Each NoteMapListenable must be closed in order to unsubscribe from the
  // repository.
  void close() {
    if (_repositorySubscription != null) {
      _repositorySubscription.cancel();
      _repositorySubscription = null;
    }
  }

  void reload() {
    repository.reload(_state.value.noteMapKey);
  }

  Future delete() async {
    if (value.existence == NoteMapExistence.exists) {
      return repository.delete(value.noteMapKey);
    }
  }

  ItemType get itemType;

  S mapItemToState(NoteMapItem item);

  @override
  void addListener(listener) => _state.addListener(listener);

  @override
  void removeListener(listener) => _state.removeListener(listener);

  @override
  S get value => _state.value;

  Future<NoteMapKey> get completeNoteMapKey => _completeKey.future;
}

class LibraryController extends NoteMapItemController<LibraryState> {
  LibraryController(NoteMapRepository repository)
      : super(repository, NoteMapKey(itemType: ItemType.LibraryItem));

  @override
  LibraryState mapItemToState(NoteMapItem item) => LibraryState(item);

  @override
  ItemType get itemType => ItemType.LibraryItem;
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
  TopicState mapItemToState(NoteMapItem item) => TopicState(item);

  @override
  ItemType get itemType => ItemType.TopicItem;

  @override
  void close() {
    removeListener(_updateFirstNameController);
    super.close();
  }
}

class NameController extends NoteMapItemController<NameState> {
  Future<TextEditingController> _valueTextController;

  NameController(
    NoteMapRepository repository,
    Int64 topicMapId,
    Int64 id, {
    Int64 parentId,
  }) : super(
          repository,
          NoteMapKey(
              topicMapId: topicMapId, id: id, itemType: ItemType.NameItem),
          parentId: parentId,
        ) {
    _valueTextController = completeNoteMapKey.then((noteMapKey) {
      var textController =
          TextEditingController(text: value.item.proto.name.value);
      textController.addListener(() {
        if (value.noteMapKey.complete) {
          repository.updateValue(value.noteMapKey, textController.text);
        }
      });
      return textController;
    }).catchError((_) => null);
  }

  @override
  NameState mapItemToState(NoteMapItem item) => NameState(item);

  @override
  ItemType get itemType => ItemType.NameItem;

  Future<TextEditingController> get valueTextController => _valueTextController;
}

class OccurrenceController extends NoteMapItemController<OccurrenceState> {
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
        );

  @override
  OccurrenceState mapItemToState(NoteMapItem item) => OccurrenceState(item);

  @override
  ItemType get itemType => ItemType.OccurrenceItem;
}
