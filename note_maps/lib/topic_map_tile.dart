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

import 'package:note_maps/topic_identicon.dart';
import 'package:note_maps/library_page/library_bloc.dart';
import 'package:note_maps/view_models.dart';

class TopicMapTile extends StatelessWidget {
  TopicMapTile({
    Key key,
    @required this.topicMap,
    this.onTap,
    this.trailing,
  })  : assert(topicMap!=null),super(key: key);

  final TopicMapViewModel topicMap;
  final void Function() onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: TopicIdenticon(
        topicMap.topicMap,
        size: 48,
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: topicMap.nameNotice,
                style: Theme.of(context).textTheme.body2.apply(
                    color: Theme.of(context)
                        .textTheme
                        .body2
                        .color
                        .withAlpha(196))),
            TextSpan(text: topicMap.name),
          ],
        ),
      ),
      trailing: _noteMapMenuButton(context),
      onTap: onTap,
    );
  }

  Widget _noteMapMenuButton(BuildContext context) {
    LibraryBloc libraryBloc=BlocProvider.of<LibraryBloc>(context);
    if(libraryBloc==null){return Container(width:0,height:0);}
    return PopupMenuButton<NoteMapOption>(
      onSelected: (NoteMapOption choice) {
        switch (choice) {
          case NoteMapOption.moveToTrash:
              libraryBloc.dispatch(
                  LibraryTopicMapMovedToTrashEvent(topicMap.topicMap.id));
            break;
          case NoteMapOption.delete:
              libraryBloc.dispatch(
                  LibraryTopicMapDeletedEvent(topicMap.topicMap.id));
            break;
          case NoteMapOption.restore:
              libraryBloc.dispatch(
                  LibraryTopicMapRestoredEvent(topicMap.topicMap.id));
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<NoteMapOption>> options =
            List<PopupMenuEntry<NoteMapOption>>();
        if (!topicMap.topicMap.inTrash) {
          options.add(const PopupMenuItem<NoteMapOption>(
            value: NoteMapOption.moveToTrash,
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('Move to Trash'),
            ),
          ));
        }
        if (topicMap.topicMap.inTrash) {
          options.add(const PopupMenuItem<NoteMapOption>(
            value: NoteMapOption.restore,
            child: ListTile(
                leading: Icon(Icons.restore_from_trash),
                title: Text('Restore')),
          ));
          options.add(const PopupMenuItem<NoteMapOption>(
            value: NoteMapOption.delete,
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ));
        }
        return options;
      },
    );
  }
}

enum NoteMapOption {
  moveToTrash,
  delete,
  restore,
}
