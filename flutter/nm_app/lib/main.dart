// Copyright 2020 Google LLC
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
import 'dart:async';

// TODO: resolve build problems with nm_gql_go_link
//import 'package:artemis/artemis.dart';
import 'package:flutter/services.dart';
// TODO: resolve build problems with nm_gql_go_link
//import 'package:nm_gql_go_link/nm_gql_go_link.dart';
//import 'package:nm_gql_go_link/note_graphql.dart';

import 'src/editor_page.dart';
import 'src/about_note_maps_list_tile.dart';

void main() {
  runApp(NmApp());
}

class NmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/editor',
      routes: {
        '/editor': (context) => EditorPage(),
      },
    );
  }
}
