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

import 'topic_map_view_models.dart';

class TopicNameEditDialog extends StatelessWidget {
  TopicNameEditDialog({Key key, @required this.topicViewModel})
      : assert(topicViewModel != null),
        super(key: key);

  final TopicViewModel topicViewModel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(topicViewModel.isTopicMap ? "Note Map Name" : "Topic Name"),
      content: TextField(
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onEditingComplete: () {
          Navigator.of(context).pop();
        },
      ),
      actions: <Widget>[
        FlatButton(
          child: new Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: new Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
