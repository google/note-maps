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
import 'mobileapi/controllers.dart';
import 'mobileapi/mobileapi.dart';
import 'style.dart';
import 'providers.dart';
import 'topic_identicon.dart';
import 'topic_map_page.dart';
import 'topic_map_title.dart';
import 'topic_page.dart';

class TopicTile extends StatelessWidget {
  TopicTile({
    Key key,
    this.noteMapKey,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  final NoteMapKey noteMapKey;
  final void Function() onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<TopicController>(context);
    return ValueListenableBuilder<TopicState>(
      valueListenable: controller,
      builder: (context, topicState, _) => Center(
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                onTap: onTap,
                child: ListTile(
                  leading: TopicIdenticon(
                    topicState.data.id,
                    size: 48,
                    backgroundColor: Theme.of(context).primaryColorLight,
                    fit: BoxFit.contain,
                  ),
                  title: Text(
                      topicState.data.names.map((n) => n.value).join(" :: ")),
                  subtitle: Text(topicState.data.occurrences
                      .map((o) => o.value)
                      .join(" :: ")),
                  trailing: PopupMenuButton<NoteMapOption>(
                    onSelected: (NoteMapOption choice) {
                      switch (choice) {
                        case NoteMapOption.delete:
                          controller.delete();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      List<PopupMenuEntry<NoteMapOption>> options =
                          List<PopupMenuEntry<NoteMapOption>>();
                      options.add(const PopupMenuItem<NoteMapOption>(
                        value: NoteMapOption.delete,
                        child: ListTile(
                          leading:
                              Icon(Icons.delete_forever, color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ));
                      return options;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NoteMapOption {
  delete,
}
