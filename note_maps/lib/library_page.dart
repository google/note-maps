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

import 'mobileapi/mobileapi.dart';
import 'providers.dart';
import 'topic_map_tile.dart';
import 'app_bottom_app_bar.dart';
import 'topic_page.dart';
import 'mobileapi/controllers.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Library"),
      ),
      body: ValueListenableBuilder<LibraryState>(
        valueListenable: Provider.of<LibraryController>(context),
        builder: (context, libraryState, _) => ListView.builder(
            itemCount: libraryState.data.topicMapIds.length,
            itemBuilder: (BuildContext context, int index) {
              var topicMapId = libraryState.data.topicMapIds[index];
              return TopicMapProvider(
                topicMapId: topicMapId,
                child: TopicMapTile(
                  onTap: () => _gotoTopicMap(context, topicMapId),
                ),
              );
            }),
      ),
      bottomNavigationBar: AppBottomAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _gotoTopicMap(context, Int64(0)),
        tooltip: 'Create a Note Map',
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _gotoTopicMap(BuildContext context, Int64 topicMapId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicMapProvider(
          topicMapId: topicMapId,
          child: TopicPage(),
        ),
      ),
    );
  }
}
