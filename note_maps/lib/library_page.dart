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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'library_bloc.dart';
import 'mobileapi/mobileapi.dart';
import 'topic_map_tile.dart';
import 'note_maps_bottom_app_bar.dart';
import 'topic_page.dart';

class LibraryPage extends StatefulWidget {
  LibraryPage({Key key, this.title = "Library"}) : super(key: key);

  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  LibraryBloc _libraryBloc;
  String _error;

  String get title => widget.title;

  @override
  void initState() {
    _libraryBloc = BlocProvider.of<LibraryBloc>(context);
    print("LibraryPage._libraryBloc.hashCode = ${_libraryBloc.hashCode}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Library"),
          bottom: TabBar(tabs: <Tab>[
            Tab(text: "All"),
            Tab(text: "Trash"),
          ]),
        ),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, libraryState) => TabBarView(
            children: <Widget>[
              listView(context, libraryState, LibraryFolder.all),
              listView(context, libraryState, LibraryFolder.trash),
            ],
          ),
        ),
        bottomNavigationBar: NoteMapsBottomAppBar(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicPage(
                  topicBloc: _libraryBloc.createTopicBloc(topic: Topic()),
                ),
              ),
            );
          },
          tooltip: 'Create a Note Map',
          child: Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget listView(
      BuildContext context, LibraryState libraryState, LibraryFolder folder) {
    if (libraryState.error != null) {
      if (_error != libraryState.error) {
        _error = libraryState.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(libraryState.error),
          ));
        });
      }
      return Center(child: Icon(Icons.bug_report, size: 48));
    }

    var list = (folder == LibraryFolder.trash)
        ? libraryState.topicMapsInTrash
        : libraryState.topicMaps;
    print(list);

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) => TopicMapTile(
        topicMap: list[index],
        onTap: folder == LibraryFolder.trash
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicPage(
                      topicBloc: _libraryBloc.createTopicBloc(
                          topic: libraryState
                              .topicMaps[index].topicViewModel.topic),
                    ),
                  ),
                );
              },
      ),
    );
  }
}
