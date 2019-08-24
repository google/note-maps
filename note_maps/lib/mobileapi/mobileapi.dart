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

import 'store/pb/pb.pb.dart';
import 'store/pb/pb.pbenum.dart';
import 'store/pb/pb.pbjson.dart';

export 'package:fixnum/fixnum.dart' show Int64;
export 'store/pb/pb.pb.dart' show Library;
export 'store/pb/pb.pb.dart' show TopicMap;
export 'store/pb/pb.pb.dart' show Topic;
export 'store/pb/pb.pb.dart' show Name;
export 'store/pb/pb.pb.dart' show Occurrence;
export 'store/pb/pb.pb.dart' show ItemType;

class NoteMapRepository {
  final QueryApi _queryApi = QueryApi();
  final CommandApi _commandApi = CommandApi();
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

  void reload(NoteMapKey item) {
    _queryApi
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

class QueryApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/query');

  Future<QueryResponse> query(QueryRequest request) async {
    return QueryResponse.fromBuffer(
        await _getRawResponse(channel, 'Query', request));
  }
}

class CommandApi {
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
