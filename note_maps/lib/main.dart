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
import 'mobileapi/controllers.dart';
import 'mobileapi/mobileapi.dart';
import 'providers.dart';

void main() => runApp(App(
      noteMapRepository: NoteMapRepository(),
    ));

class App extends StatefulWidget {
  final NoteMapRepository noteMapRepository;

  App({
    Key key,
    @required this.noteMapRepository,
  })  : assert(noteMapRepository != null),
        super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin<App> {
  LibraryController libraryListenable;
  AppNavigationBloc appNavigationBloc;

  @override
  void initState() {
    super.initState();
    libraryListenable = LibraryController(widget.noteMapRepository);
    appNavigationBloc = AppNavigationBloc();
  }

  @override
  void dispose() {
    libraryListenable.close();
    appNavigationBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NoteMapRepository>.value(value: widget.noteMapRepository),
        LibraryProvider(),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppNavigationBloc>(
              builder: (context) => appNavigationBloc),
        ],
        child: MaterialApp(
          title: 'Note Maps',
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            accentColor: Color.fromARGB(0xff, 0x8b, 0x6e, 0x60),
          ),
          home: BlocBuilder<AppNavigationBloc, AppNavigationState>(
            builder: (context, state) {
              return AppNavigationStack();
            },
          ),
        ),
      ),
    );
  }
}
