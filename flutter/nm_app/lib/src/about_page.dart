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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatefulWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _goLinkStatus = 'Unknown';
  String _appVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _reloadStatus();
    rootBundle.loadString('assets/version.txt').then((String version) {
      if (!mounted) return;
      setState(() {
        _appVersion = version;
      });
    });
  }

  void _reloadStatus() async {
    String goLinkStatus = 'uninitialized';
    if (!mounted) return;
    setState(() {
      _goLinkStatus = goLinkStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Note Maps $_appVersion',
            ),
            Text(
              'Storage system: $_goLinkStatus',
            ),
          ],
        ),
      ),
    );
  }
}
