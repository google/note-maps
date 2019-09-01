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

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers.dart';
import 'mobileapi/mobileapi.dart';

abstract class NoteMapItemProvider<S extends NoteMapItemState,
    L extends NoteMapItemController<S>> extends StatefulWidget {
  final L Function(NoteMapRepository repository, NoteMapKey noteMapKey) builder;
  final Widget child;
  final NoteMapKey initialNoteMapKey;

  NoteMapItemProvider({
    Key key,
    @required this.initialNoteMapKey,
    @required this.builder,
    this.child,
  })  : assert(initialNoteMapKey != null),
        assert(builder != null);

  @override
  State<StatefulWidget> createState() {
    return _NoteMapItemProviderState<S, L>();
  }
}

class _NoteMapItemProviderState<S extends NoteMapItemState,
        L extends NoteMapItemController<S>>
    extends State<NoteMapItemProvider<S, L>> {
  NoteMapRepository repository;
  L listenable;

  @override
  void dispose() {
    if (listenable != null) {
      listenable.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (repository == null) {
      repository = Provider.of<NoteMapRepository>(context);
    }
    if (listenable == null) {
      listenable = widget.builder(repository, widget.initialNoteMapKey);
    }

    Widget result = widget.child;
    if (listenable is TopicMapController) {
      TopicMapController topicMapController = listenable as TopicMapController;
      result = FutureProvider<TopicController>(
        builder: (_) => topicMapController.topicController,
        child: result,
      );
    }
    if (listenable is TopicController) {
      TopicController topicController = listenable as TopicController;
      result = ValueListenableProvider<NameController>(
        builder: (_) => topicController.firstNameController,
        child: result,
      );
    }

    return InheritedProvider<L>(
      value: listenable,
      child: ValueListenableProvider<S>.value(
        value: listenable,
        child: result,
      ),
      updateShouldNotify: (prev, next) => false,
    );
  }
}

class LibraryProvider
    extends NoteMapItemProvider<LibraryState, LibraryController>
    implements SingleChildCloneableWidget {
  LibraryProvider({
    Key key,
    Widget child,
  }) : super(
          key: key,
          child: child,
          initialNoteMapKey: NoteMapKey(itemType: ItemType.LibraryItem),
          builder: (repository, _) => LibraryController(repository),
        );

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) => LibraryProvider(
        child: child,
      );
}

class TopicMapProvider
    extends NoteMapItemProvider<TopicMapState, TopicMapController>
    implements SingleChildCloneableWidget {
  TopicMapProvider({
    Key key,
    Int64 topicMapId,
    Widget child,
  })  : assert(topicMapId != null),
        super(
          key: key,
          child: child,
          initialNoteMapKey: NoteMapKey(
            topicMapId: topicMapId,
            id: topicMapId,
            itemType: ItemType.TopicMapItem,
          ),
          builder: (repository, key) =>
              TopicMapController(repository, key.topicMapId),
        );

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) => TopicMapProvider(
        topicMapId: initialNoteMapKey.topicMapId,
        child: child,
      );
}

class TopicProvider extends NoteMapItemProvider<TopicState, TopicController>
    implements SingleChildCloneableWidget {
  TopicProvider({
    Key key,
    @required Int64 topicMapId,
    Int64 topicId,
    Widget child,
  })  : assert(topicMapId != null),
        super(
          key: key,
          child: child,
          initialNoteMapKey: NoteMapKey(
            topicMapId: topicMapId,
            id: topicId ?? Int64(0),
            itemType: ItemType.TopicItem,
          ),
          builder: (repository, key) => TopicController(
            repository,
            key.topicMapId,
            key.id,
          ),
        );

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) => TopicProvider(
        topicMapId: initialNoteMapKey.topicMapId,
        topicId: initialNoteMapKey.id,
        child: child,
      );
}

class NameProvider extends NoteMapItemProvider<NameState, NameController>
    implements SingleChildCloneableWidget {
  NameProvider({
    Key key,
    @required Int64 topicMapId,
    Int64 nameId,
    Int64 parentId,
    Widget child,
  })  : assert(topicMapId != null),
        super(
          key: key,
          child: child,
          initialNoteMapKey: NoteMapKey(
            topicMapId: topicMapId,
            id: nameId,
            itemType: ItemType.NameItem,
          ),
          builder: (repository, key) => NameController(
            repository,
            key.topicMapId,
            key.id,
            parentId: parentId,
          ),
        );

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) => TopicProvider(
        topicMapId: initialNoteMapKey.topicMapId,
        topicId: initialNoteMapKey.id,
        child: child,
      );
}

class OccurrenceProvider
    extends NoteMapItemProvider<OccurrenceState, OccurrenceController>
    implements SingleChildCloneableWidget {
  OccurrenceProvider({
    Key key,
    @required Int64 topicMapId,
    Int64 nameId,
    Int64 parentId,
    Widget child,
  })  : assert(topicMapId != null),
        super(
          key: key,
          child: child,
          initialNoteMapKey: NoteMapKey(
            topicMapId: topicMapId,
            id: nameId,
            itemType: ItemType.OccurrenceItem,
          ),
          builder: (repository, key) => OccurrenceController(
            repository,
            key.topicMapId,
            key.id,
            parentId: parentId,
          ),
        );

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) => TopicProvider(
        topicMapId: initialNoteMapKey.topicMapId,
        topicId: initialNoteMapKey.id,
        child: child,
      );
}
