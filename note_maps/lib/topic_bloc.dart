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

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

import 'library_bloc.dart';
import 'mobileapi/mobileapi.dart';

class TopicBloc extends Bloc<TopicEvent, TopicState> {
  final QueryApi queryApi;
  final CommandApi commandApi;
  final LibraryBloc libraryBloc;

  TopicBloc({
    @required this.queryApi,
    @required this.commandApi,
    @required this.libraryBloc,
    Topic topic,
    Int64 topicId,
  })  : assert(libraryBloc != null),
        assert(topic == null || topicId == null),
        assert(topic != null || topicId != null) {
    if (topic != null) {
      dispatch(TopicLoadedEvent(topic: topic));
    } else {
      dispatch(TopicLoadEvent(topicId: topicId));
    }
  }

  @override
  TopicState get initialState {
    return TopicState();
  }

  @override
  Stream<TopicState> mapEventToState(TopicEvent event) async* {
    if (event is TopicLoadEvent) {
      yield TopicState(loading: true);
      yield TopicState(
          error: "load existing topic? nope, not implemented yet.");
    } else if (event is TopicLoadedEvent) {
      yield TopicState(topic: event.topic);
      if (event.topic.id == 0 && event.topic.topicMapId != 0) {
        TopicState state;
        await commandApi
            .createTopicMap(CreateTopicMapRequest())
            .then((response) {
          state = TopicState(topic: response.topicMap.topic);
          // Since a new topic map has been created, tell the library bloc.
          libraryBloc.dispatch(LibraryReloadEvent());
        }).catchError((error) {
          print(error);
          state = TopicState(error: error.toString());
        });
        yield state;
      } else {
        // Create a new topic.
        // TODO: create a new topic!
        print("creating a new topic? nope, not implemented yet.");
      }
    }
    print("finished processing topic load event");
  }

  TopicBloc createOtherTopicBloc({Topic other}) {
    other = other ?? Topic();
    if (other.topicMapId == 0) {
      other.topicMapId = currentState.topic?.topicMapId ?? Int64(0);
    }
    return TopicBloc(
        queryApi: queryApi,
        commandApi: commandApi,
        libraryBloc: libraryBloc,
        topic: other);
  }
}

class TopicState {
  final bool loading;
  final Topic topic;
  final String error;
  final List<Name> names;
  final List<Occurrence> occurrences;

  TopicState({
    Topic topic,
    this.loading = false,
    this.error,
  })  : assert(loading != null),
        topic = topic ?? Topic(),
        names = topic == null
            ? const []
            : topic.names.length == 0
                ? <Name>[
                    Name().copyWith((n) {
                      n.parentId = topic.id;
                    })
                  ]
                : topic.names,
        occurrences = topic == null
            ? const []
            : topic.occurrences.length == 0
                ? <Occurrence>[
                    Occurrence().copyWith((o) {
                      o.parentId = topic.id;
                    })
                  ]
                : topic.occurrences;

  bool get isTopicMap => topic.id != 0 && topic.id == topic.topicMapId;

  bool get exists => topic.id != 0;

  String get nameNotice =>
      name != "" ? "" : "Unnamed " + (isTopicMap ? "Note Map" : "Topic");

  String get name {
    if (topic.names == null || topic.names.length == 0) {
      return "";
    }
    return topic.names[0].value ?? "";
  }
}

class TopicEvent {}

class TopicLoadEvent extends TopicEvent {
  final Int64 topicId;

  TopicLoadEvent({this.topicId});
}

class TopicLoadedEvent extends TopicEvent {
  final Topic topic;

  TopicLoadedEvent({this.topic});
}
