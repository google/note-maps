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

import 'item_icon.dart';
import 'library_bloc.dart';
import 'topic_screen.dart';
import 'topic_map_view_models.dart';

class LibraryPage extends StatefulWidget {
  LibraryPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  LibraryBloc _libraryBloc;
  String _error;

  String get title => widget.title;

  @override
  void initState() {
    _libraryBloc = BlocProvider.of<LibraryBloc>(context);
    print("LibraryPage._libraryBloc.hashCode = ${_libraryBloc.hashCode}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        body: BlocBuilder<LibraryBloc, LibraryState>(
          bloc: _libraryBloc,
          builder: (context, libraryState) =>
              scrollView(context, orientation, libraryState),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicPage(
                  topicBloc: _libraryBloc.createTopicBloc(),
                ),
              ),
            );
          },
          tooltip: 'Create a Note Map',
          child: Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget scrollView(BuildContext context, Orientation orientation,
      LibraryState libraryState) {
    List<Widget> widgets = List<Widget>();
    widgets.add(SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: orientation == Orientation.portrait ? 160.0 : null,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title),
        //background: Image.asset(..., fit: BoxFit.fill)
      ),
    ));
    if (libraryState.error != null) {
      widgets.add(SliverFillRemaining(
        child: Center(
          child: Icon(Icons.bug_report),
        ),
      ));
      if (_error != libraryState.error) {
        _error = libraryState.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(libraryState.error),
          ));
        });
      }
    } else if (libraryState.loading) {
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
            (BuildContext context, int index) =>
                noteMapTile(context, libraryState.topicMaps[index]),
            childCount: libraryState.topicMaps.length,
          ),
        ),
      ));
    }
    return CustomScrollView(slivers: widgets);
  }

  Widget noteMapTile(BuildContext context, TopicMapViewModel topicMap) {
    return ListTile(
      leading: ItemIcon(topicMap.topicMap),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: topicMap.nameNotice, style: Theme.of(context).textTheme.body2.apply(color: Theme.of(context).textTheme.body2.color.withAlpha(196))),
            TextSpan(text: topicMap.name),
            TextSpan(text: " ("+topicMap.topicMap.id.toRadixString(16)+")", style:Theme.of(context).textTheme.body1),
          ],
        ),
      ),
      trailing: noteMapMenuButton(),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicPage(
                topicBloc: _libraryBloc.createTopicBloc(
                    viewModel: topicMap.topicViewModel)),
          ),
        );
      },
    );
  }

  Widget noteMapMenuButton() {
    return PopupMenuButton<NoteMapOption>(
      onSelected: (NoteMapOption choice) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteMapOption>>[
        const PopupMenuItem<NoteMapOption>(
          value: NoteMapOption.rename,
          child: Text('Rename'),
        ),
        const PopupMenuItem<NoteMapOption>(
          value: NoteMapOption.moveToTrash,
          child: Text('Move to Trash'),
        ),
      ],
    );
  }
}

enum NoteMapOption {
  rename,
  moveToTrash,
}
