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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'library_bloc.dart';
import 'note_maps_sliver_app_bar.dart';
import 'topic_map_tile.dart';
import 'note_maps_bottom_app_bar.dart';
import 'trash_bloc.dart';

class TrashPage extends StatefulWidget {
  TrashPage({Key key, this.navigatorKey}) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  LibraryBloc _libraryBloc;
  TrashBloc _trashBloc;
  String _error;

  @override
  void initState() {
    _libraryBloc = BlocProvider.of<LibraryBloc>(context);
    _trashBloc = TrashBloc(libraryBloc: _libraryBloc);
    _trashBloc.dispatch(TrashReloadEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      builder: (context) => _libraryBloc,
      child: Navigator(
        key: widget.navigatorKey,
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => OrientationBuilder(
              builder: (context, orientation) => Theme(
                data: Theme.of(context).copyWith(primaryColor: Colors.black),
                child: Scaffold(
                  body: BlocBuilder<TrashBloc, TrashState>(
                    builder: (context, trashState) =>
                        scrollView(context, orientation, trashState),
                  ),
                  bottomNavigationBar: NoteMapsBottomAppBar(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget scrollView(
      BuildContext context, Orientation orientation, TrashState trashState) {
    List<Widget> widgets = List<Widget>();
    widgets.add(NoteMapsSliverAppBar(
      orientation: orientation,
      title: Text("Trash"),
    ));
    if (trashState.error != null) {
      widgets.add(SliverFillRemaining(
        child: Center(
          child: Icon(Icons.bug_report),
        ),
      ));
      if (_error != trashState.error) {
        _error = trashState.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(trashState.error),
          ));
        });
      }
    } else if (trashState.loading) {
      widgets.add(SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ));
    } else {
      widgets.add(SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => TopicMapTile(
              trashBloc: _trashBloc,
              topicMapViewModel: trashState.topicMaps[index],
            ),
            childCount: trashState.topicMaps.length,
          ),
        ),
      ));
    }
    return CustomScrollView(slivers: widgets);
  }
}
