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

import 'mobileapi/mobileapi.dart';
import 'topic_bloc.dart';
import 'topic_map_view_models.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final QueryApi queryApi;
  final CommandApi commandApi;

  LibraryBloc({
    @required this.queryApi,
    @required this.commandApi,
  });

  @override
  LibraryState get initialState => LibraryState(loading: true);

  @override
  Stream<LibraryState> mapEventToState(LibraryEvent event) async* {
    if (event is LibraryAppStartedEvent) {
      yield LibraryState(loading: true);
      yield await _loadTopicMaps();
    }

    if (event is LibraryReloadEvent) {
      yield await _loadTopicMaps();
    }

    if (event is LibraryTopicMapMovedToTrashEvent) {
      DeleteTopicMapRequest request = DeleteTopicMapRequest();
      request.topicMapId = event.topicMapId;
      await commandApi.deleteTopicMap(request);
      yield await _loadTopicMaps();
    }

    if (event is LibraryTopicMapDeletedEvent) {
      DeleteTopicMapRequest request = DeleteTopicMapRequest();
      request.topicMapId = event.topicMapId;
      request.fullyDelete = true;
      await commandApi.deleteTopicMap(request);
      yield await _loadTopicMaps();
    }

    if (event is LibraryTopicMapRestoredEvent) {
      RestoreTopicMapRequest request = RestoreTopicMapRequest();
      request.topicMapId = event.topicMapId;
      await commandApi.restoreTopicMap(request);
      yield await _loadTopicMaps();
    }
  }

  Future<LibraryState> _loadTopicMaps() async {
    LibraryState next;
    await Future.wait(
      LibraryFolder.values.map((folder) async =>
          await queryApi.getTopicMaps(GetTopicMapsRequest().copyWith((r) {
            r.inTrash = folder == LibraryFolder.trash;
          }))),
    ).then((responses) {
      next = LibraryState(
        topicMaps: responses[LibraryFolder.all.index]
            .topicMaps
            .map((tm) => TopicMapViewModel(tm))
            .toList(growable: false),
        topicMapsInTrash: responses[LibraryFolder.trash.index]
            .topicMaps
            .map((tm) => TopicMapViewModel(tm))
            .toList(growable: false),
      );
    }).catchError((error) {
      next = LibraryState(error: error.toString());
    });
    return next;
  }

  TopicBloc createTopicBloc({Topic topic}) => TopicBloc(
        queryApi: queryApi,
        commandApi: commandApi,
        libraryBloc: this,
        topic: topic,
      );
}

class LibraryState {
  final List<TopicMapViewModel> topicMaps;
  final List<TopicMapViewModel> topicMapsInTrash;
  final bool loading;
  final String error;

  LibraryState({
    this.topicMaps = const [],
    this.topicMapsInTrash = const [],
    this.loading = false,
    this.error,
  }) : assert(topicMaps != null);
}

enum LibraryFolder {
  all,
  trash,
}

class LibraryEvent extends Equatable {}

class LibraryAppStartedEvent extends LibraryEvent {}

class LibraryReloadEvent extends LibraryEvent {}

class LibraryTopicMapMovedToTrashEvent extends LibraryEvent {
  final Int64 topicMapId;

  LibraryTopicMapMovedToTrashEvent(this.topicMapId)
      : assert(topicMapId != null && topicMapId != 0);
}

class LibraryTopicMapRestoredEvent extends LibraryEvent {
  final Int64 topicMapId;

  LibraryTopicMapRestoredEvent(this.topicMapId)
      : assert(topicMapId != null && topicMapId != 0);
}

class LibraryTopicMapDeletedEvent extends LibraryEvent {
  final Int64 topicMapId;

  LibraryTopicMapDeletedEvent(this.topicMapId)
      : assert(topicMapId != null && topicMapId != 0);
}
