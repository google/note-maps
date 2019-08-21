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

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

import 'library_bloc.dart';
import 'mobileapi/mobileapi.dart';
import 'topic_map_view_models.dart';

class TopicBloc extends Bloc<TopicEvent, TopicState> {
  final QueryApi queryApi;
  final CommandApi commandApi;
  final LibraryBloc libraryBloc;
  TopicViewModel previousViewModel;
  TopicViewModel viewModel;

  TopicBloc({
    @required this.queryApi,
    @required this.commandApi,
    @required this.libraryBloc,
    this.previousViewModel,
    this.viewModel,
  }) : assert(libraryBloc != null);

  @override
  TopicState get initialState {
    return TopicState();
  }

  @override
  Stream<TopicState> mapEventToState(TopicEvent event) async* {
    if (event is TopicLoadEvent) {
      print("processing topic load event");
      if (viewModel == null || !viewModel.exists) {
        print("yielding 'loading' state");
        yield TopicState(loading: true);
        if (viewModel == null || viewModel.isTopicMap) {
          // Create a new topic map.
          print("creating a new topic map");
          TopicState state;
          await commandApi
              .createTopicMap(CreateTopicMapRequest())
              .then((response) {
            viewModel = TopicViewModel(response.topicMap.topic);
            print("${viewModel.topic.id}");
            state = TopicState(viewModel: viewModel);
            libraryBloc.dispatch(LibraryReloadEvent());
          }).catchError((error) {
            print(error);
            state = TopicState(error: error.toString());
          });
          print(state);
          yield state;
        } else {
          // Create a new topic.
          // TODO: create a new topic!
          print("creating a new topic");
        }
      } else {
        // Just load the topic as it is.
        print("using existing topic");
        yield TopicState(viewModel: viewModel);
      }
      print("finished processing topic load event");
    }

    if (event is TopicNameChangedEvent) {
      if (viewModel.topic.names.length == 0) {
        // Create a new name
      } else {
        // Edit existing name
      }
    }
  }

  TopicBloc createOtherTopicBloc({TopicViewModel otherViewModel}) {
    if (otherViewModel?.topic == null && viewModel?.topic != null) {
      Topic topic = Topic();
      topic.topicMapId = viewModel.topic.topicMapId;
      otherViewModel = TopicViewModel(topic);
    }
    return TopicBloc(
        queryApi: queryApi,
        commandApi: commandApi,
        libraryBloc: libraryBloc,
        previousViewModel: viewModel,
        viewModel: otherViewModel);
  }
}

class TopicState {
  final TopicViewModel viewModel;
  final bool loading;
  final String error;

  TopicState({
    TopicViewModel viewModel,
    this.loading = false,
    this.error,
  }) : viewModel = viewModel ?? TopicViewModel(null);
}

class TopicEvent {}

class TopicLoadEvent extends TopicEvent {
  TopicLoadEvent();
}

class TopicNameChangedEvent extends TopicEvent {
  final String name;

  TopicNameChangedEvent(this.name);
}
