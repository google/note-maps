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
import 'dart:typed_data' show Uint8List;

import 'package:dcache/dcache.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'note_map_item.dart';
import 'note_map_key.dart';
import 'store/pb/pb.pb.dart';
import 'store/pb/pb.pbenum.dart';

class NoteMapRepository {
  final _QueryApi _queryApi = _QueryApi();
  final _CommandApi _commandApi = _CommandApi();
  final StreamController<String> _errors = StreamController<String>();
  final StreamController<NoteMapItem> _items =
      StreamController<NoteMapItem>.broadcast();
  final Cache<NoteMapKey, NoteMapItem> _cache =
      SimpleCache<NoteMapKey, NoteMapItem>(
          storage: SimpleStorage<NoteMapKey, NoteMapItem>(size: 100));

  Stream<String> get errors => _errors.stream;

  Stream<NoteMapItem> get items => _items.stream;

  void close() {
    _errors.close();
    _items.close();
    _cache.clear();
  }

  void reloadLibrary() {
    reload(NoteMapKey(
      topicMapId: Int64(0),
      id: Int64(0),
      itemType: ItemType.LibraryItem,
    ));
  }

  Future<void> reload(NoteMapKey item) async {
    return _queryApi
        .query(QueryRequest().copyWith((q) {
      var request = LoadRequest();
      request.topicMapId = item.topicMapId;
      request.id = item.id;
      request.itemType = item.itemType;
      q.loadRequests.add(request);
    }))
        .then((response) {
      response.loadResponses.forEach((LoadResponse loaded) {
        _handleItem(NoteMapItem.fromItem(loaded.item));
      });
    }).catchError((error) {
      _errors.sink.add(error.toString());
    });
  }

  void _reloadParent(
      {Int64 topicMapId, Int64 parentId, ItemType childItemType}) {
    switch (childItemType) {
      case ItemType.NameItem:
      case ItemType.OccurrenceItem:
        if (parentId != null && parentId != Int64(0)) {
          reload(NoteMapKey(
            topicMapId: topicMapId,
            id: parentId,
            itemType: ItemType.TopicItem,
          ));
        }
        break;
      case ItemType.TopicMapItem:
        reload(NoteMapKey(itemType: ItemType.LibraryItem));
        break;
      default:
        break;
    }
  }

  NoteMapItem fromCache(NoteMapKey key) {
    return _cache.get(key);
  }

  Future<NoteMapItem> create(
    Int64 topicMapId,
    Int64 parentId,
    ItemType itemType,
  ) async {
    return Future.sync(() async {
      print("creating $topicMapId, $parentId, $itemType");
      var creation = CreationRequest();
      creation.topicMapId = topicMapId;
      creation.parent = parentId;
      creation.itemType = itemType;
      var m = MutationRequest();
      m.creationRequests.add(creation);
      var response = await _mutate(m);
      _reloadParent(
        topicMapId: topicMapId,
        parentId: parentId,
        childItemType: itemType,
      );
      return NoteMapItem.fromItem(response.creationResponses[0].item);
    }).catchError((error) {
      print("error while creating $itemType: $error");
      throw error;
    });
  }

  Future<bool> updateValue(NoteMapKey noteMapKey, String value) async {
    return Future.sync(() async {
      var valueUpdate = UpdateValueRequest();
      valueUpdate.topicMapId = noteMapKey.topicMapId;
      valueUpdate.id = noteMapKey.id;
      valueUpdate.itemType = noteMapKey.itemType;
      valueUpdate.value = value;
      var m = MutationRequest();
      m.updateValueRequests.add(valueUpdate);
      await _mutate(m);
      return true;
    }).catchError((e) {
      // TODO: handle error!
      print("ignoring error: $e");
      return false;
    });
  }

  Future<NoteMapItem> delete(NoteMapKey key, {Int64 parentId}) async {
    var deletion = DeletionRequest();
    deletion.topicMapId = key.topicMapId;
    deletion.id = key.id;
    deletion.itemType = key.itemType;
    var m = MutationRequest();
    m.deletionRequests.add(deletion);
    var response = await _mutate(m);
    _reloadParent(
      topicMapId: key.topicMapId,
      parentId: parentId,
      childItemType: key.itemType,
    );
    var deleted = response.deletionResponses[0];
    return NoteMapItem.deleted(NoteMapKey(
      topicMapId: deleted.topicMapId,
      id: deleted.id,
      itemType: deleted.itemType,
    ));
  }

  Future<List<NoteMapKey>> search(Int64 topicMapId) async {
    return _queryApi
        .query(QueryRequest().copyWith((q) =>
            q.searchRequests.add(SearchRequest()..topicMapIds.add(topicMapId))))
        .then((response) => response.searchResponses[0].items.map((item) {
              var noteMapItem = NoteMapItem.fromItem(item);
              _handleItem(noteMapItem);
              return noteMapItem.noteMapKey;
            }).toList());
  }

  Future<MutationResponse> _mutate(MutationRequest request) async {
    MutationResponse futureResponse;
    await _commandApi.mutate(request).then((response) {
      futureResponse = response;
      response.deletionResponses.forEach((deletion) {
        _handleItem(NoteMapItem.deleted(NoteMapKey(
            topicMapId: deletion.topicMapId,
            id: deletion.id,
            itemType: deletion.itemType)));
      });
      response.creationResponses.forEach(
          (creation) => _handleItem(NoteMapItem.fromItem(creation.item)));
      response.updateOrderResponses
          .forEach((update) => _handleItem(NoteMapItem.fromItem(update.item)));
      response.updateValueResponses
          .forEach((update) => _handleItem(NoteMapItem.fromItem(update.item)));
    });
    return futureResponse;
  }

  void _updateCache(NoteMapItem item) {
    _cache.set(item.noteMapKey, item);
  }

  void _handleItem(NoteMapItem item) {
    _updateCache(item);
    _items.add(item);
  }
}

class _QueryApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/query');

  Future<QueryResponse> query(QueryRequest request) async {
    return QueryResponse.fromBuffer(
        await _getRawResponse(channel, 'Query', request));
  }
}

class _CommandApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/command');

  Future<MutationResponse> mutate(MutationRequest request) async {
    return MutationResponse.fromBuffer(
        await _getRawResponse(channel, 'Mutate', request));
  }
}

Future<Uint8List> _getRawResponse(
    MethodChannel channel, String method, $pb.GeneratedMessage request) async {
  final Uint8List rawRequest = request.writeToBuffer();
  final Uint8List rawResponse = await channel.invokeMethod(method, {
    "request": rawRequest,
  });
  return rawResponse ?? Uint8List(0);
}
