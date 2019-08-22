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
import 'package:flutter_bloc/flutter_bloc.dart';

import 'topic_bloc.dart';
import 'topic_map_view_models.dart';
import 'note_maps_bottom_app_bar.dart';
import 'topic_tab_bar.dart';

class TopicPage extends StatefulWidget {
  TopicPage({Key key, @required this.topicBloc})
      : assert(topicBloc != null),
        super(key: key);

  final TopicBloc topicBloc;

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  TopicBloc get _topicBloc => widget.topicBloc;

  @override
  Widget build(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return BlocProvider<TopicBloc>(
      builder: (_) => _topicBloc,
      child: OrientationBuilder(
        builder: (context, orientation) => BlocBuilder<TopicBloc, TopicState>(
          builder: (context, topicState) => Scaffold(
            resizeToAvoidBottomPadding: true,
            appBar: AppBar(
              title: Text("Library"),
              bottom: TopicTabBar(
                textTheme: Theme.of(context).primaryTextTheme,
              ),
            ),
            body: topicState.loading
                ? Center(child: CircularProgressIndicator())
                : _createContent(context, topicState),
            floatingActionButton: (showFab && topicState.exists)
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicPage(
                              topicBloc: _topicBloc.createOtherTopicBloc()),
                        ),
                      );
                    },
                    tooltip: 'Create a related Topic',
                    child: Icon(Icons.insert_link),
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: NoteMapsBottomAppBar(),
          ),
        ),
      ),
    );
  }

  Widget _createContent(BuildContext context, TopicState topicState) {
    List<Widget> form = List<Widget>();
    form.add(heading("Names"));
    form.addAll(
      topicState.names.map(
        (name) => Card(
          child: Row(
            children: <Widget>[
              Container(width: 48),
              Expanded(
                child: TextField(
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  style: Theme.of(context).textTheme.title,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              noteMenuButton(),
            ],
          ),
        ),
      ),
    );
    form.add(Divider());
    form.add(heading("Notes"));
    form.addAll(
      topicState.occurrences.map(
        (occurrence) => Card(
          child: Row(
            children: <Widget>[
              Container(width: 48),
              Expanded(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              noteMenuButton(),
            ],
          ),
        ),
      ),
    );
    form.add(Divider());
    form.add(heading("Associations"));

    return ListView(
      children: form,
    );
  }

  Widget heading(String text) => Padding(
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

  Widget noteTile(BuildContext context, OccurrenceViewModel occurrence) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          IconButton(
              onPressed: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              icon: Icon(
                Icons.drag_handle,
                color: Theme.of(context).primaryColor,
              )),
          Flexible(
            child: TextField(
              controller: occurrence.value,
              maxLines: null,
              decoration: null,
            ),
          ),
          noteMenuButton(),
        ],
      ),
    );
  }

  Widget roleTile(BuildContext context) {
    return ListTile(
      leading: FlutterLogo(),
      title: Placeholder(
        fallbackHeight: 20,
      ),
      trailing: roleMenuButton(),
      onTap: () {
        // TODO: identify topic associated with role; should already be part of
        // view model in this context, and pass it on to the next TopicPage.
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TopicPage(topicBloc: _topicBloc.createOtherTopicBloc())),
        );
      },
    );
  }

  Widget noteMenuButton() {
    return PopupMenuButton<NoteOption>(
      onSelected: (NoteOption choice) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteOption>>[
        const PopupMenuItem<NoteOption>(
          value: NoteOption.delete,
          child: Text('Delete note'),
        ),
      ],
    );
  }

  Widget roleMenuButton() {
    return PopupMenuButton<RoleOption>(
      onSelected: (RoleOption choice) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<RoleOption>>[
        const PopupMenuItem<RoleOption>(
          value: RoleOption.editRole,
          child: Text('Edit role'),
        ),
        const PopupMenuItem<RoleOption>(
          value: RoleOption.editAssociation,
          child: Text('Edit association'),
        ),
      ],
    );
  }
}

enum NoteOption { delete }
enum RoleOption {
  editRole,
  editAssociation,
}
