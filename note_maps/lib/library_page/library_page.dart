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

import '../controllers/controllers.dart';
import '../mobileapi/mobileapi.dart';
import '../mobileapi/store/pb/pb.pb.dart';
import '../navigation.dart';
import '../widgets/widgets.dart';
import 'topic_map_tile.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image(
            image: AssetImage('assets/images/launcher.png'),
          ),
        ),
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
                child: TopicMapTile(),
              );
            }),
      ),
      floatingActionButton: AutoFab(
        onCreated: (noteMapKey) {
          switch (noteMapKey.itemType) {
            case ItemType.TopicMapItem:
              _gotoTopicMap(context, noteMapKey.id, initiallyEditing: true);
              return;
            default:
              throw ("no handler for created ${noteMapKey.itemType}");
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _gotoTopicMap(BuildContext context, Int64 topicMapId,
      {bool initiallyEditing = false}) {
    Navigator.pushNamed(context, TopicPageArguments.routeName,
        arguments: TopicPageArguments(
          topicMapId: topicMapId,
          topicId: topicMapId,
          initiallyEditing: initiallyEditing,
        ));
  }
}
