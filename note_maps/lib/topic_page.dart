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
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'cards.dart';
import 'mobileapi/controllers.dart';
import 'mobileapi/mobileapi.dart';
import 'providers.dart';

class TopicPage extends StatefulWidget {
  final bool initiallyEditing;

  TopicPage({Key key, this.initiallyEditing = false})
      : assert(initiallyEditing != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  bool editing;
  ScrollController scrollController;
  bool fabVisibleIfNotEditing = true;

  @override
  void initState() {
    super.initState();
    editing = widget.initiallyEditing;
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
    var topicController = Provider.of<TopicController>(context);
    if (topicController == null) {
      return Container(child: CircularProgressIndicator());
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ValueListenableBuilder<TopicState>(
        valueListenable: topicController,
        builder: (context, TopicState topicState, _) => Scaffold(
          resizeToAvoidBottomPadding: true,
          appBar: AppBar(
            title: Text(topicState.data.topicMapId == topicState.data.id
                ? "Note Map"
                : "Topic"),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    editing = !editing;
                  });
                },
              ),
            ],
          ),
          body: topicState.existence == NoteMapExistence.notExists
              ? Center(child: CircularProgressIndicator())
              : _buildForm(context, topicState),
          floatingActionButton: SpeedDial(
            child: Icon(Icons.add),
            tooltip: 'Add item',
            visible: fabVisibleIfNotEditing && !editing,
            marginRight: MediaQuery.of(context).size.width / 2 - 28,
            children: [
              SpeedDialChild(
                child: Icon(Icons.add_circle_outline),
                label: 'Note',
                onTap: () {
                  topicController.createOccurrence().catchError((error) =>
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString()))));
                  setState(() {
                    // TODO: focus text field of added note.
                    editing = true;
                  });
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.add_circle),
                label: 'Name',
                onTap: () {
                  topicController.createName().catchError((error) =>
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString()))));
                  setState(() {
                    // TODO: focus text field of added name.
                    editing = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, TopicState topicState) {
    var nameIds = topicState.data.nameIds;
    if (nameIds.length == 0) {
      nameIds = [Int64(0)];
    }
    var fieldCount = 0;
    List<Widget> form = List<Widget>();
    form.add(_buildFormSubheading(context, "Names"));
    form.addAll(
      nameIds.map((nameId) => NameProvider(
            topicMapId: topicState.noteMapKey.topicMapId,
            parentId: topicState.noteMapKey.id,
            nameId: nameId,
            child: editing
                ? NameField(autofocus: (fieldCount++) == 0)
                : NameCard(),
          )),
    );
    form.add(Divider());
    form.add(_buildFormSubheading(context, "Notes"));
    form.addAll(
      topicState.data.occurrenceIds.map((occurrenceId) => OccurrenceProvider(
            topicMapId: topicState.noteMapKey.topicMapId,
            parentId: topicState.noteMapKey.id,
            nameId: occurrenceId,
            child: editing
                ? OccurrenceField(autofocus: (fieldCount++) == 0)
                : OccurrenceCard(),
          )),
    );

    return FocusScope(
      autofocus: true,
      child: ListView(
        controller: scrollController,
        children: form,
      ),
    );
  }

  Widget _buildFormSubheading(BuildContext context, String text) => Padding(
        padding: EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.overline.copyWith(),
            textAlign: TextAlign.left,
          ),
        ),
      );

  Future<bool> _onWillPop() async {
    if (!editing) {
      return true;
    }
    setState(() {
      editing = false;
    });
    return false;
  }
}
