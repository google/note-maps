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
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../mobileapi/mobileapi.dart';
import '../style.dart';

// AutoFab is a magical floating action button that looks for known types of
// controllers and presents options for creating any kind of child item those
// controllers can create.
class AutoFab extends StatelessWidget {
  final bool visible;
  final Function(NoteMapKey) onCreated;
  final List<Type> _controllerTypes = <Type>[
    OccurrenceController,
    NameController,
    TopicController,
    TopicMapController,
    LibraryController,
  ];

  AutoFab({this.visible = true, this.onCreated});

  Type _type<T>() => T;

  NoteMapItemController maybeController<T extends NoteMapItemController>(
      BuildContext context) {
    var provider =
        context.inheritFromWidgetOfExactType(_type<InheritedProvider<T>>())
            as InheritedProvider<T>;
    if (provider == null) {
      return null;
    }
    return Provider.of<T>(context);
  }

  @override
  Widget build(BuildContext context) {
    var children = List<_ChildCreator>();
    <NoteMapItemController>[
      maybeController<OccurrenceController>(context),
      maybeController<NameController>(context),
      maybeController<TopicController>(context),
      maybeController<TopicMapController>(context),
      maybeController<LibraryController>(context),
    ].where((c) => c != null).forEach((c) =>
        children.addAll(c.canCreateChildTypes.map((childType) => _ChildCreator(
              controller: c,
              childType: childType,
              onTap: () {
                c.createChild(childType).then(onCreated).catchError((error) =>
                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString()))));
              },
            ))));
    switch (children.length) {
      case 0:
        return Container();
      case 1:
        return visible
            ? FloatingActionButton(
                child: Icon(Icons.add),
                tooltip: 'Add ' + children[0].toolTip,
                onPressed: children[0].onTap,
              )
            : Container();
      default:
        return SpeedDial(
          child: Icon(Icons.add),
          tooltip: 'Add item',
          visible: visible,
          marginRight: MediaQuery.of(context).size.width / 2 - 28,
          children: children
              .map(
                (c) => SpeedDialChild(
                  child: c.buildChild(context),
                  label: c.toolTip,
                  onTap: c.onTap,
                ),
              )
              .toList(growable: false),
        );
    }
  }
}

class _ChildCreator {
  final ItemType childType;
  final NoteMapItemController controller;
  final Function onTap;

  const _ChildCreator({
    this.controller,
    this.childType,
    this.onTap,
  });

  String get toolTip {
    switch (childType) {
      case ItemType.LibraryItem:
        throw ("cannot create new library");
      case ItemType.TopicMapItem:
        return "Note Map";
      case ItemType.TopicItem:
        return "Topic";
      case ItemType.NameItem:
        return "Name";
      case ItemType.OccurrenceItem:
        return "Note";
      default:
        throw ("unrecognized item type");
    }
  }

  Widget buildChild(BuildContext context) {
    switch (childType) {
      case ItemType.LibraryItem:
        throw ("cannot create new library");
      case ItemType.TopicMapItem:
        return Icon(NoteMapIcons.add_topic_map);
      case ItemType.TopicItem:
        return Icon(NoteMapIcons.add_topic);
      case ItemType.NameItem:
        return Icon(NoteMapIcons.add_name);
      case ItemType.OccurrenceItem:
        return Icon(NoteMapIcons.add_occurrence);
      default:
        throw ("unrecognized item type");
    }
  }
}
