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

import 'mobileapi/mobileapi.dart';

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
