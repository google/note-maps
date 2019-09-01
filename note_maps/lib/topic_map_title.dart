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
import 'package:provider/provider.dart';

import 'common_widgets.dart';
import 'controllers.dart';

class TopicMapTitle extends StatelessWidget {
  final Widget Function(BuildContext, String) builder;

  TopicMapTitle({this.builder});

  Widget _build(BuildContext context, String title) {
    if (builder != null) {
      return builder(context, title);
    }
    return Text(title);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TopicController>(
        future: Provider.of<TopicMapController>(context).topicController,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return ErrorIndicator();
          }
          return ValueListenableBuilder<NameController>(
              valueListenable: snapshot.data.firstNameController,
              builder: (context, nameController, _) {
                if (nameController == null) {
                  return _build(context, "Unnamed Note Map");
                } else {
                  return ValueListenableBuilder<NameState>(
                    valueListenable: nameController,
                    builder: (context, nameState, _) => _build(
                        context,
                        nameState.data.value == ""
                            ? "Unnamed Note Map"
                            : nameState.data.value),
                  );
                }
              });
        });
  }
}
