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

import 'package:flutter/widgets.dart';

import 'package:note_maps/mobileapi/mobileapi.dart';

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
  final List<NameViewModel> names;
  final List<OccurrenceViewModel> occurrences;

  TopicViewModel(this.topic)
      : names = ((topic?.names != null && topic.names.length > 0)
                ? topic.names
                : <Name>[Name()])
            .map((n) => NameViewModel(name: n))
            .toList(growable: false),
        occurrences =
            ((topic?.occurrences != null && topic.occurrences.length > 0)
                    ? topic.occurrences
                    : <Occurrence>[Occurrence()])
                .map((o) => OccurrenceViewModel(occurrence: o))
                .toList(growable: false);

  String get nameNotice =>
      name != "" ? "" : "Unnamed " + (isTopicMap ? "Note Map" : "Topic");

  String get name {
    if (topic == null || topic.names == null || topic.names.length == 0) {
      return "";
    }
    return topic.names[0].value ?? "";
  }

  bool get isTopicMap => topic?.id == topic?.topicMapId;

  bool get exists => topic != null && topic.id != 0;
}

class NameViewModel {
  final Name _name;
  final TextEditingController value;

  bool get tentative => _name == null || _name.id == 0;

  NameViewModel({Name name})
      : _name = name,
        value = TextEditingController(text: name?.value);
}

class OccurrenceViewModel {
  final Occurrence _occurrence;
  final TextEditingController value;

  bool get tentative => _occurrence == null || _occurrence.id == 0;

  OccurrenceViewModel({Occurrence occurrence})
      : _occurrence = occurrence,
        value = TextEditingController(text: occurrence?.value);
}
