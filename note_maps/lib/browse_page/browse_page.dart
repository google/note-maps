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

import '../controllers/controllers.dart';
import '../mobileapi/mobileapi.dart';
import '../widgets/widgets.dart';
import 'browse_search_results.dart';

class BrowsePage extends StatefulWidget {
  BrowsePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  TopicMapController topicMapController;
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
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text("Note Map"),
      ),
      body: BrowseSearchResults(),
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
    );
  }
}
