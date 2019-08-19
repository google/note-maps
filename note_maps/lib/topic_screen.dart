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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import 'item_icon.dart';
import 'library_bloc.dart';
import 'mobileapi/mobileapi.dart';
import 'topic_map_view_models.dart';
import 'topic_name_edit_dialog.dart';
import 'note_maps_app_bar.dart';

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
  void initState() {
    _topicBloc.dispatch(TopicLoadEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TopicBloc>(
      builder: (_) => _topicBloc,
      child: OrientationBuilder(
        builder: (context, orientation) => BlocBuilder<TopicBloc, TopicState>(
          bloc: _topicBloc,
          builder: (context, topicState) => Scaffold(
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
                    title: Text(topicState.viewModel.nameNotice +
                        topicState.viewModel.name),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ItemIcon(
                          topicState.viewModel.topic,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        ),
                        BackdropFilter(
                          filter:
                              new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: new Container(
                            decoration: new BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                      onPressed: topicState.viewModel == null
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => TopicNameEditDialog(
                                  topicViewModel: topicState.viewModel,
                                ),
                              ).then((newName) {
                                _topicBloc
                                    .dispatch(TopicNameChangedEvent(newName));
                              });
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
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => noteTile(context,
                          topicState.viewModel.occurrenceViewModels[i]),
                      childCount:
                          topicState.viewModel?.occurrenceViewModels?.length ??
                              0,
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: topicState.viewModel?.exists
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
            bottomNavigationBar: NoteMapsAppBar(),
          ),
        ),
      ),
    );
  }

  Widget noteTile(
      BuildContext context, OccurrenceViewModel occurrenceViewModel) {
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
                text: occurrenceViewModel.occurrence.value,
              ),
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

class TopicBloc extends Bloc<TopicEvent, TopicState> {
  final QueryApi queryApi;
  final CommandApi commandApi;
  final LibraryBloc libraryBloc;
  TopicViewModel previousViewModel;
  TopicViewModel viewModel;

  TopicBloc({
    @required this.queryApi,
    @required this.commandApi,
    @required this.libraryBloc,
    this.previousViewModel,
    this.viewModel,
  }) : assert(libraryBloc != null);

  @override
  TopicState get initialState {
    return TopicState();
  }

  @override
  Stream<TopicState> mapEventToState(TopicEvent event) async* {
    if (event is TopicLoadEvent) {
      print("processing topic load event");
      if (viewModel == null || !viewModel.exists) {
        print("yielding 'loading' state");
        yield TopicState(loading: true);
        if (viewModel == null || viewModel.isTopicMap) {
          // Create a new topic map.
          print("creating a new topic map");
          TopicState state;
          await commandApi
              .createTopicMap(CreateTopicMapRequest())
              .then((response) {
            viewModel = TopicViewModel(response.topicMap.topic);
            print("${viewModel.topic.id}");
            state = TopicState(viewModel: viewModel);
            libraryBloc.dispatch(LibraryReloadEvent());
          }).catchError((error) {
            print(error);
            state = TopicState(error: error.toString());
          });
          print(state);
          yield state;
        } else {
          // Create a new topic.
          // TODO: create a new topic!
          print("creating a new topic");
        }
      } else {
        // Just load the topic as it is.
        print("using existing topic");
        yield TopicState(viewModel: viewModel);
      }
      print("finished processing topic load event");
    }

    if (event is TopicNameChangedEvent) {
      // TODO: update topic name to event.name;
    }
  }

  TopicBloc createOtherTopicBloc({TopicViewModel otherViewModel}) {
    if (otherViewModel?.topic == null && viewModel?.topic != null) {
      Topic topic = Topic();
      topic.topicMapId = viewModel.topic.topicMapId;
      otherViewModel = TopicViewModel(topic);
    }
    return TopicBloc(
        queryApi: queryApi,
        commandApi: commandApi,
        libraryBloc: libraryBloc,
        previousViewModel: viewModel,
        viewModel: otherViewModel);
  }
}

class TopicState {
  final TopicViewModel viewModel;
  final bool loading;
  final String error;

  TopicState({
    TopicViewModel viewModel,
    this.loading = false,
    this.error,
  }) : viewModel = viewModel ?? TopicViewModel(null);
}

class TopicEvent {}

class TopicLoadEvent extends TopicEvent {
  TopicLoadEvent();
}

class TopicNameChangedEvent extends TopicEvent {
  final String name;

  TopicNameChangedEvent(this.name);
}
