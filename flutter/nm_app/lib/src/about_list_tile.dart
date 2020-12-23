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

class NmAboutListTile extends StatefulWidget {
  NmAboutListTile({Key key}) : super(key: key);

  @override
  _NmAboutListTileState createState() => _NmAboutListTileState();
}

class _NmAboutListTileState extends State<NmAboutListTile> {
  String _goLinkStatus = 'Unknown';
  String _appVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/version.txt').then((String version) {
      if (!mounted) return;
      setState(() {
        _appVersion = version;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AboutListTile(
      icon: Icon(Icons.info),
      applicationIcon: FlutterLogo(),
      applicationName: 'Note Maps',
      applicationVersion: _appVersion,
      applicationLegalese: 'Apache License 2.0',
    );
  }
}
