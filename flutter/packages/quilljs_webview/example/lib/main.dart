import 'package:flutter/material.dart';
import 'package:quilljs_webview/quilljs_webview.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('QuillJS WebView Example'),
      ),
      body: QuillJSWebView(),
    ),
  ));
}
