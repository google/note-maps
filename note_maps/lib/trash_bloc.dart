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

import 'package:bloc/bloc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'library_bloc.dart';
import 'mobileapi/mobileapi.dart';
import 'topic_map_view_models.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final LibraryBloc libraryBloc;

  QueryApi get queryApi => libraryBloc.queryApi;

  CommandApi get commandApi => libraryBloc.commandApi;

  TrashBloc({
    @required this.libraryBloc,
  });

  @override
  TrashState get initialState {
    return TrashState();
  }

  @override
  Stream<TrashState> mapEventToState(TrashEvent event) async* {
    if (event is TrashReloadEvent) {
      yield await _loadTopicMaps();
    }

    if (event is TrashTopicMapDeletedEvent) {
      DeleteTopicMapRequest request = DeleteTopicMapRequest();
      request.topicMapId = event.topicMapId;
      request.fullyDelete = true;
      await commandApi.deleteTopicMap(request);
      yield await _loadTopicMaps();
    }

    if (event is TrashTopicMapRestoredEvent) {
      RestoreTopicMapRequest request = RestoreTopicMapRequest();
      request.topicMapId = event.topicMapId;
      await commandApi
          .restoreTopicMap(request)
          .then((_) => libraryBloc.dispatch(LibraryReloadEvent()));
      yield await _loadTopicMaps();
    }
  }

  Future<TrashState> _loadTopicMaps() async {
    TrashState next;
    GetTopicMapsRequest request = GetTopicMapsRequest();
    request.inTrash = true;
    await queryApi.getTopicMaps(request).then((response) {
      next = TrashState(
        topicMaps: (response.topicMaps ?? const [])
            .map((tm) => TopicMapViewModel(tm))
            .toList(growable: false),
      );
    }).catchError((error) {
      next = TrashState(error: error.toString());
    });
    return next;
  }
}

class TrashState {
  final List<TopicMapViewModel> topicMaps;
  final bool loading;
  final String error;

  TrashState({
    this.topicMaps = const [],
    this.loading = false,
    this.error,
  }) : assert(topicMaps != null);

  @override
  String toString() => "TrashState(${topicMaps.length}, ${loading}, ${error})";
}

class TrashEvent extends Equatable {}

class TrashReloadEvent extends TrashEvent {}

class TrashTopicMapDeletedEvent extends TrashEvent {
  final Int64 topicMapId;

  TrashTopicMapDeletedEvent(this.topicMapId)
      : assert(topicMapId != null && topicMapId != 0);
}

class TrashTopicMapRestoredEvent extends TrashEvent {
  final Int64 topicMapId;

  TrashTopicMapRestoredEvent(this.topicMapId)
      : assert(topicMapId != null && topicMapId != 0);
}
