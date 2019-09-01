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
import 'package:flutter/widgets.dart';

import '../mobileapi/mobileapi.dart';

abstract class NoteMapItemState<T> {
  final NoteMapItem item;

  NoteMapItemState(this.item) : assert(item != null);

  NoteMapKey get noteMapKey => item.noteMapKey;

  NoteMapExistence get existence => item.existence;

  T get data;
}

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
