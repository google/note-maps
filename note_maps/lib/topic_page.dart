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

import 'app_bottom_app_bar.dart';
import 'cards.dart';
import 'mobileapi/controllers.dart';
import 'mobileapi/mobileapi.dart';
import 'providers.dart';
import 'topic_map_title.dart';

class TopicPage extends StatelessWidget {
  TopicPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var topicListenable = Provider.of<TopicController>(context);
    if (topicListenable == null) {
      return Container(child: CircularProgressIndicator());
    }
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return ValueListenableBuilder<TopicState>(
      valueListenable: topicListenable,
      builder: (context, TopicState topicState, _) => Scaffold(
        resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          title: Text(topicState.data.topicMapId == topicState.data.id
              ? "Note Map"
              : "Topic"),
        ),
        body: topicState.existence == NoteMapExistence.notExists
            ? Center(child: CircularProgressIndicator())
            : _createForm(context, topicState),
        floatingActionButton:
            (showFab && topicState.existence == NoteMapExistence.exists)
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicProvider(
                            topicMapId: topicState.data.topicMapId,
                            child: TopicPage(),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Create a related Topic',
                    child: Icon(Icons.insert_link),
                  )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomAppBar(),
      ),
    );
  }

  Widget _createForm(BuildContext context, TopicState topicState) {
    var nameIds = topicState.data.nameIds;
    if (nameIds.length == 0) {
      nameIds = [Int64(0)];
    }
    List<Widget> form = List<Widget>();
    form.add(heading(context, "Names"));
    form.addAll(
      nameIds.map((nameId) => NameProvider(
            topicMapId: topicState.noteMapKey.topicMapId,
            parentId: topicState.noteMapKey.id,
            nameId: nameId,
            child: NameCard(),
          )),
    );
    form.add(Divider());
    form.add(heading(context, "Notes"));
    form.addAll(
      topicState.data.occurrenceIds.map((occurrenceId) => OccurrenceProvider(
            topicMapId: topicState.noteMapKey.topicMapId,
            parentId: topicState.noteMapKey.id,
            nameId: occurrenceId,
            child: OccurrenceCard(),
          )),
    );
    form.add(Divider());
    form.add(heading(context, "Associations"));

    return ListView(
      children: form,
    );
  }

  Widget heading(BuildContext context, String text) => Padding(
        padding: EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: Theme.of(context).textTheme.overline,
            textAlign: TextAlign.left,
          ),
        ),
      );
}
