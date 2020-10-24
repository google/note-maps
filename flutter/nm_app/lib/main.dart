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

import 'package:artemis/artemis.dart';
import 'package:flutter/services.dart';
import 'package:nm_gql_go_link/nm_gql_go_link.dart';
import 'package:nm_gql_go_link/note_graphql.dart';
import 'package:quilljs_webview/quilljs_webview.dart';

import 'src/editor_page.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => NmHomePage(title: 'Note Maps'),
        '/editor': (context) => EditorPage(),
      },
    );
  }
}

class NmHomePage extends StatefulWidget {
  NmHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NmHomePageState createState() => _NmHomePageState();
}

class _NmHomePageState extends State<NmHomePage> {
  String _goLinkStatus = 'Unknown';
  NmGqlGoLink _goLink = NmGqlGoLink();

  @override
  void initState() {
    super.initState();
    _reloadStatus();
  }

  void _reloadStatus() async {
    String goLinkStatus;
    try {
      ArtemisClient client = ArtemisClient.fromLink(_goLink);
      final statusQuery = NoteStatusQuery();
      final statusResponse = await client.execute(statusQuery);
      goLinkStatus = statusResponse.data.status.summary;
      client.dispose();
    } on PlatformException {
      goLinkStatus = 'Failed to get GraphQL link status.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _goLinkStatus = goLinkStatus;
    });
  }

  void _openEditor() {
    Navigator.pushNamed(context, '/editor');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Storage system: $_goLinkStatus',
            ),
            RaisedButton(
              child: Text('Launch Editor'),
              onPressed: _openEditor,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        tooltip: 'Create Note',
        child: Icon(Icons.add),
      ),
    );
  }
}
