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

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'auto_fab.dart';
import 'mobileapi/controllers.dart';
import 'mobileapi/mobileapi.dart';
import 'topic_identicon.dart';

class TopicMapPage extends StatefulWidget {
  TopicMapPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopicMapPageState();
}

class _TopicMapPageState extends State<TopicMapPage> {
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
    var controller = Provider.of<TopicMapController>(context);
    if (controller == null) {
      return Container(child: CircularProgressIndicator());
    }
    return ValueListenableBuilder<TopicMapState>(
      valueListenable: controller,
      builder: (context, TopicMapState topicMapState, _) => Scaffold(
        resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          title: Text("Note Map"),
        ),
        body: topicMapState.existence == NoteMapExistence.notExists
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: 15,
                itemBuilder: (context, index) => ListTile(
                      leading: TopicIdenticon(
                        Int64(0),
                        size: 48,
                      ),
                      title: Text("Topic"),
                      trailing: IconButton(icon:Icon(Icons.folder)),
                    )),
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
