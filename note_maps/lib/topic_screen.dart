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

class TopicPage extends StatelessWidget {
  TopicPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation) => Scaffold(
              resizeToAvoidBottomPadding: true,
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    snap: false,
                    floating: false,
                    expandedHeight:
                        orientation == Orientation.portrait ? 160.0 : null,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(title),
                      //background: Image.asset(..., fit: BoxFit.fill)
                    ),
                    actions: <Widget>[
                      IconButton(
                        onPressed: () {
                          showRenameTopicDialog(context);
                        },
                        icon: Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.delete),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        noteTile(context),
                        noteTile(context),
                        noteTile(context),
                        Divider(),
                        roleTile(context),
                        roleTile(context),
                        roleTile(context),
                        roleTile(context),
                        roleTile(context),
                        roleTile(context),
                      ]),
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TopicPage(title: "Unnamed Topic")),
                  );
                },
                tooltip: 'Create a related Topic',
                child: Icon(Icons.insert_link),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                child: Container(
                  height: 50.0,
                ),
              ),
            ));
  }

  showRenameTopicDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Rename Topic"),
              content: TextField(
                autofocus: true,
                onEditingComplete: () {
                  Navigator.of(context).pop();
                },
              ),
              actions: <Widget>[
                FlatButton(
                  child: new Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: new Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  Widget noteTile(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          IconButton(
              onPressed: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              icon: Icon(Icons.drag_handle)),
          Flexible(
            child: TextField(
              controller: TextEditingController(
                  text: "Lorem ipsum dolor sit amet, consectetur adipiscing " +
                      "elit. Sed tristique tristique purus, at aliquet eros " +
                      "gravida malesuada. Ut vehicula convallis eros, in " +
                      "tristique nunc tincidunt ac."),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TopicPage(title: "Topic")),
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
