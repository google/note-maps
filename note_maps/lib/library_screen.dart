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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mobileapi/mobileapi.dart';
import 'topic_screen.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation) => Scaffold(
              body: Consumer<LibraryState>(
                  builder: (context, libraryState, child) => CustomScrollView(
                        slivers: <Widget>[
                          SliverAppBar(
                            pinned: true,
                            snap: false,
                            floating: false,
                            expandedHeight: orientation == Orientation.portrait
                                ? 160.0
                                : null,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(title),
                              //background: Image.asset(..., fit: BoxFit.fill)
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) =>
                                      noteMapTile(context,
                                          libraryState.topicMaps[index]),
                                  childCount: libraryState.topicMaps.length),
                            ),
                          ),
                        ],
                      )),
              bottomNavigationBar: BottomAppBar(
                child: Container(
                  height: 50.0,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TopicPage(title: "Unnamed Note Map")),
                  );
                },
                tooltip: 'Create a Note Map',
                child: Icon(Icons.add),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
            ));
  }

  Widget noteMapTile(BuildContext context, TopicMap topicMap) {
    return ListTile(
      title: Text(
        topicMap.id.toRadixString(16),
      ),
      trailing: noteMapMenuButton(),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TopicPage(title: "Topic Map")),
        );
      },
    );
  }

  Widget noteMapMenuButton() {
    return PopupMenuButton<NoteMapOption>(
      onSelected: (NoteMapOption choice) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteMapOption>>[
        const PopupMenuItem<NoteMapOption>(
          value: NoteMapOption.rename,
          child: Text('Rename'),
        ),
        const PopupMenuItem<NoteMapOption>(
          value: NoteMapOption.moveToTrash,
          child: Text('Move to Trash'),
        ),
      ],
    );
  }
}

enum NoteMapOption {
  rename,
  moveToTrash,
}

class Library {
  final QueryApi query;
  final CommandApi command;
  final StreamController<LibraryState> _state =
      StreamController<LibraryState>.broadcast();

  Library(this.query, this.command) {}

  Stream<LibraryState> state() => _state.stream;

  void dispose() {
    _state.close();
  }
}

class LibraryState {
  final List<TopicMap> topicMaps;
  final bool loaded;

  LibraryState({this.topicMaps = const [], this.loaded = false});
}
