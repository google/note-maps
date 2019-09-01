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
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'auto_fab.dart';
import 'common_widgets.dart';
import 'mobileapi/mobileapi.dart';
import 'providers.dart';
import 'topic_page.dart';
import 'topic_tile.dart';
import 'controllers.dart';

class BrowsePage extends StatefulWidget {
  BrowsePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  SearchController controller;
  ScrollController scrollController;
  bool fabVisibleIfNotEditing = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() {
    bool fabVisible = scrollController.position.userScrollDirection ==
        ScrollDirection.forward;
    setState(() {
      fabVisibleIfNotEditing = fabVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      var topicMapController = Provider.of<TopicMapController>(context);
      if (topicMapController == null) {
        return ErrorIndicator();
      }
      controller = SearchController(
          repository: Provider.of<NoteMapRepository>(context),
          topicMapId: topicMapController.value.noteMapKey.topicMapId);
      controller.load();
    }
    return ValueListenableBuilder<SearchState>(
      valueListenable: controller,
      builder: (context, SearchState searchState, _) => Scaffold(
        resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          title: Text("Note Map"),
        ),
        body: searchState.error != null
            ? Container()
            : ListView.builder(
                itemCount: searchState.estimatedCount,
                itemBuilder: (context, index) =>
                    index < searchState.known.length
                        ? TopicProvider(
                            topicMapId: searchState.known[index].topicMapId,
                            topicId: searchState.known[index].id,
                            child: TopicTile(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MultiProvider(
                                    providers: [
                                      TopicMapProvider(
                                          topicMapId: searchState
                                              .known[index].topicMapId),
                                      TopicProvider(
                                        topicMapId:
                                            searchState.known[index].topicMapId,
                                        topicId: searchState.known[index].id,
                                      ),
                                    ],
                                    child: TopicPage(initiallyEditing: false),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
              ),
        floatingActionButton: AutoFab(
          visible: fabVisibleIfNotEditing,
          onCreated: (newKey) {
            switch (newKey.itemType) {
              case ItemType.TopicMapItem:
                break;
              case ItemType.TopicItem:
                break;
              case ItemType.NameItem:
                break;
              case ItemType.OccurrenceItem:
                break;
              default:
                throw ("unexpected item type ${newKey.itemType}");
            }
          },
        ),
      ),
    );
  }
}
