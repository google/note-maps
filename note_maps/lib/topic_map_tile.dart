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
import 'topic_identicon.dart';
import 'topic_map_title.dart';

class TopicMapTile extends StatelessWidget {
  TopicMapTile({
    Key key,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  final void Function() onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<TopicMapController>(context);
    return ValueListenableBuilder<TopicMapState>(
      valueListenable: controller,
      builder: (context, topicMapState, _) => Center(
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                onTap: onTap,
                child: ListTile(
                  leading: TopicIdenticon(
                    topicMapState.data.topic,
                    size: 48,
                    backgroundColor: Theme.of(context).primaryColorLight,
                    fit: BoxFit.contain,
                  ),
                  title: TopicMapTitle(),
                  subtitle: Text(
                      "Last modified sometime after this app was installed"),
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
              ButtonTheme.bar(
                child: ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: const Text('NEW TOPIC'),
                      onPressed: () {
                        Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text("Not implemented yet, sorry!")));
                      },
                    ),
                    FlatButton(
                      child: const Text('BROWSE'),
                      onPressed: () {
                        Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text("Not implemented yet, sorry!")));
                      },
                    ),
                  ],
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
