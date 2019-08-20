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

import 'mobileapi/mobileapi.dart';

class TopicMapViewModel {
  final TopicMap topicMap;
  final TopicViewModel topicViewModel;

  TopicMapViewModel(this.topicMap)
      : topicViewModel = TopicViewModel(topicMap?.topic);

  String get nameNotice => topicViewModel.nameNotice;

  String get name => topicViewModel.name;

  Topic get topic => topicMap.topic;
}

class TopicViewModel {
  final Topic topic;
  final List<OccurrenceViewModel> occurrenceViewModels;

  TopicViewModel(this.topic)
      : occurrenceViewModels = (topic?.occurrences ?? const [])
            .map((o) => OccurrenceViewModel(occurrence: o))
            .toList(growable: false);

  String get nameNotice =>
      name != "" ? "" : "Unnamed " + (isTopicMap ? "Note Map" : "Topic");

  String get name {
    if (topic == null || topic.names == null||topic.names.length==0) {
      return "";
    }
    return topic.names[0].value ?? "";
  }

  bool get isTopicMap => topic?.id == topic?.topicMapId;

  bool get exists => topic != null && topic.id != 0;
}

class OccurrenceViewModel {
  final Occurrence occurrence;

  OccurrenceViewModel({this.occurrence});
}
