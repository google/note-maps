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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'library_screen.dart';
import 'mobileapi/mobileapi.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    QueryApi query = QueryApi();
    CommandApi command = CommandApi();
    Library library = Library(query, command);
    return MultiProvider(
      providers: [
        Provider<QueryApi>.value(value: query),
        Provider<CommandApi>.value(value: command),
        Provider<Library>.value(value: Library(query, command)),
        StreamProvider<LibraryState>.value(
          value: library.state(),
          initialData: LibraryState(),
        ),
      ],
      child: MaterialApp(
        title: 'Note Maps',
        theme: ThemeData(
          primarySwatch: Colors.grey,
        ),
        home: LibraryPage(title: 'Note Maps Library'),
      ),
    );
  }
}
