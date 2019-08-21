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

import 'item_icon.dart';
import 'library_bloc.dart';
import 'topic_map_view_models.dart';
import 'trash_bloc.dart';

class TopicMapTile extends StatelessWidget {
  TopicMapTile({
    Key key,
    this.libraryBloc,
    this.trashBloc,
    @required this.topicMapViewModel,
    this.onTap,
    this.trailing,
  })  : assert(topicMapViewModel != null),
        super(key: key);

  final LibraryBloc libraryBloc;
  final TrashBloc trashBloc;
  final TopicMapViewModel topicMapViewModel;
  final void Function() onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ItemIcon(topicMapViewModel.topicMap),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: topicMapViewModel.nameNotice,
                style: Theme.of(context).textTheme.body2.apply(
                    color: Theme.of(context)
                        .textTheme
                        .body2
                        .color
                        .withAlpha(196))),
            TextSpan(text: topicMapViewModel.name),
          ],
        ),
      ),
      trailing: _noteMapMenuButton(),
      onTap: onTap,
    );
  }

  Widget _noteMapMenuButton() {
    return PopupMenuButton<NoteMapOption>(
      onSelected: (NoteMapOption choice) {
        switch (choice) {
          case NoteMapOption.moveToTrash:
            if (libraryBloc != null) {
              libraryBloc.dispatch(
                  LibraryTopicMapDeletedEvent(topicMapViewModel.topicMap.id));
            }
            break;
          case NoteMapOption.delete:
            if (trashBloc != null) {
              trashBloc.dispatch(
                  TrashTopicMapDeletedEvent(topicMapViewModel.topicMap.id));
            }
            break;
          case NoteMapOption.restore:
            if (trashBloc != null) {
              trashBloc.dispatch(
                  TrashTopicMapRestoredEvent(topicMapViewModel.topicMap.id));
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<NoteMapOption>> options =
            List<PopupMenuEntry<NoteMapOption>>();
        if (libraryBloc != null && !topicMapViewModel.topicMap.inTrash) {
          options.add(const PopupMenuItem<NoteMapOption>(
            value: NoteMapOption.moveToTrash,
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('Move to Trash'),
            ),
          ));
        }
        if (trashBloc != null && topicMapViewModel.topicMap.inTrash) {
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
