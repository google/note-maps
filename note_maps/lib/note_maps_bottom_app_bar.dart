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

import 'app_navigation_bloc.dart';

class NoteMapsBottomAppBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NoteMapsBottomAppBarState();
  }
}

class _NoteMapsBottomAppBarState extends State<NoteMapsBottomAppBar> {
  AppNavigationBloc appNavigationBloc;

  @override
  void initState() {
    appNavigationBloc = BlocProvider.of<AppNavigationBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Drawer(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.home),
                          title: Text('Note Maps'),
                          onTap: () {
                            appNavigationBloc.dispatch(
                                AppNavigationEvent(AppNavigationPage.library));
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Trash'),
                          onTap: () {
                            appNavigationBloc.dispatch(
                                AppNavigationEvent(AppNavigationPage.trash));
                            Navigator.pop(context);
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.info),
                          title: Text('About'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
