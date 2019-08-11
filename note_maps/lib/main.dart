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

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Maps',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: LibraryPage(title: 'Note Maps Library'),
    );
  }
}

class LibraryPage extends StatefulWidget {
  LibraryPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const queryChannel =
      const MethodChannel('github.com/google/note-maps/query');
  static const commandChannel =
      const MethodChannel('github.com/google/note-maps/query');

  String _response;

  Future _getTopicMaps() async {
    String response = "";
    try {
      final String result = await queryChannel.invokeMethod('GetTopicMaps');
      response = result;
    } on PlatformException catch (e) {
      response = "Failed to Invoke: '${e.message}'";
    }
    setState(() {
      _response = response;
    });
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
              "Response:",
            ),
            Text(
              '$_response',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getTopicMaps,
        tooltip: 'Get Topic Maps',
        child: Icon(Icons.add),
      ),
    );
  }
}
