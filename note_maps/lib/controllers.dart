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

import 'mobileapi/mobileapi.dart';
import 'mobileapi/store/pb/pb.pb.dart';

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

  List<ItemType> get canCreateChildTypes => const [];

  Future<NoteMapKey> createChild(ItemType childType) async {
    return await repository
        .create(value.noteMapKey.topicMapId, value.noteMapKey.id, childType)
        .then((response) => response.noteMapKey)
        .catchError((error) {
      throw error;
    });
  }
}

class LibraryController extends NoteMapItemController<LibraryState> {
  LibraryController(NoteMapRepository repository)
      : super(repository, NoteMapKey(itemType: ItemType.LibraryItem));

  @override
  LibraryState mapItemToState(NoteMapItem item) => LibraryState(item);

  @override
  ItemType get itemType => ItemType.LibraryItem;

  @override
  List<ItemType> get canCreateChildTypes => const [ItemType.TopicMapItem];
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

class _NoteMapItemValueController {
  final NoteMapItemController itemController;
  Future<TextEditingController> _futureTextController;
  TextEditingController _textController;

  _NoteMapItemValueController(this.itemController) {
    _futureTextController = itemController.completeNoteMapKey
        .then((noteMapKey) => _textController = TextEditingController(
            text: itemController.value.item.proto.name.value)
          ..addListener(_textControllerChanged))
        .catchError((_) => null);
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

class NameController extends NoteMapItemController<NameState> {
  _NoteMapItemValueController _valueController;

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
    _valueController = _NoteMapItemValueController(this);
  }

  @override
  close() {
    _valueController.close();
  }

  Future<TextEditingController> get valueTextController =>
      _valueController.textController;

  @override
  NameState mapItemToState(NoteMapItem item) => NameState(item);

  @override
  ItemType get itemType => ItemType.NameItem;
}

class OccurrenceController extends NoteMapItemController<OccurrenceState> {
  _NoteMapItemValueController _valueController;

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
    _valueController = _NoteMapItemValueController(this);
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

class SearchState {
  final int estimatedCount;
  final List<NoteMapKey> known;
  final Error error;

  const SearchState.prime()
      : estimatedCount = 1,
        known = const [],
        error = null;

  SearchState.partial(List<NoteMapKey> known)
      : estimatedCount = known.length + 1,
        known = known.toList(growable: false),
        error = null;

  SearchState.complete(List<NoteMapKey> known)
      : estimatedCount = known.length,
        known = known.toList(growable: false),
        error = null;

  SearchState.error(Error error)
      : estimatedCount = 0,
        known = const [],
        error = error;
}

class SearchController extends ValueListenable<SearchState> {
  final NoteMapRepository repository;
  final Int64 topicMapId;
  final ValueNotifier<SearchState> _valueNotifier;

  SearchController({this.repository, this.topicMapId})
      : assert(repository != null),
        assert(topicMapId != null && topicMapId != Int64(0)),
        _valueNotifier = ValueNotifier(SearchState.prime());

  Future<void> load() async {
    await repository.search(topicMapId).then((noteMapKeys) {
      print("search result: ${noteMapKeys.length}");
      _valueNotifier.value = SearchState.complete(noteMapKeys);
    }).catchError((error) {
      print("search error: ${error}");
      return _valueNotifier.value = SearchState.error(error);
    });
  }

  @override
  void addListener(listener) => _valueNotifier.addListener(listener);

  @override
  void removeListener(listener) => _valueNotifier.removeListener(listener);

  @override
  SearchState get value => _valueNotifier.value;
}
