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
import 'package:provider/provider.dart';

import 'app_navigation_bloc.dart';
import 'app_navigation_stack.dart';
import 'library_bloc.dart';
import 'library_navigator.dart';
import 'library_screen.dart';
import 'mobileapi/mobileapi.dart';
import 'trash_screen.dart';

void main() => runApp(App(
      queryApi: QueryApi(),
      commandApi: CommandApi(),
    ));

class App extends StatefulWidget {
  final QueryApi queryApi;
  final CommandApi commandApi;

  App({
    Key key,
    @required this.queryApi,
    @required this.commandApi,
  }) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin<App> {
  LibraryBloc libraryBloc;
  AppNavigationBloc appNavigationBloc;

  QueryApi get queryApi => widget.queryApi;

  CommandApi get commandApi => widget.commandApi;

  @override
  void initState() {
    super.initState();
    libraryBloc = LibraryBloc(queryApi: queryApi, commandApi: commandApi);
    libraryBloc.dispatch(LibraryAppStartedEvent());
    appNavigationBloc = AppNavigationBloc();
  }

  @override
  void dispose() {
    libraryBloc.dispose();
    appNavigationBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<QueryApi>.value(value: queryApi),
        Provider<CommandApi>.value(value: commandApi),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LibraryBloc>(builder: (context) => libraryBloc),
          BlocProvider<AppNavigationBloc>(
              builder: (context) => appNavigationBloc),
        ],
        child: MaterialApp(
          title: 'Note Maps',
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            accentColor: Color.fromARGB(0xff, 0x8b, 0x6e, 0x60),
          ),
          home: BlocBuilder(
            bloc: appNavigationBloc,
            builder: (context, state) {
              return AppNavigationStack();
            },
          ),
        ),
      ),
    );
  }
}
