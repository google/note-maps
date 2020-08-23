import 'package:flutter/material.dart';
import 'dart:async';

import 'package:artemis/artemis.dart';
import 'package:flutter/services.dart';
import 'package:nm_gql_go_link/nm_gql_go_link.dart';
import 'package:nm_gql_go_link/note_graphql.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _goVersion = 'Unknown';
  String _goLinkStatus = 'Unknown';
  NmGqlGoLink _goLink = NmGqlGoLink();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    String goVersion;
    String goLinkStatus;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await NmGqlGoLink.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    try {
      goVersion = await NmGqlGoLink.goVersion;
    } on PlatformException {
      goVersion = 'Failed to get Go version.';
    }
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
      _platformVersion = platformVersion;
      _goVersion = goVersion;
      _goLinkStatus = goLinkStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('Backend: $_goVersion\n'),
              Text('GraphQL: $_goLinkStatus\n'),
            ],
          ),
        ),
      ),
    );
  }
}
