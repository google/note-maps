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

/// Thie quilljs_webview package provides a QuillJS editor in a Flutter
/// WebView.
library quilljs_webview;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A QuillJS editor in a WebViewScaffold.
class QuillJSWebView extends StatefulWidget {
  QuillJSWebView({Key key}) : super(key: key);

  @override
  _QuillJSWebViewState createState() => _QuillJSWebViewState();
}

class _QuillJSWebViewState extends State<QuillJSWebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  final Future<List<String>> _quill = Future.wait([
    rootBundle.loadString(
        'packages/quilljs_webview/third_party/quilljs/quill.snow.css'),
    rootBundle.loadString(
        'packages/quilljs_webview/third_party/quilljs/quill.min.js'),
  ]);
  final int _css = 0;
  final int _js = 1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _quill,
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Text('Error: %{snapshot.error}');
          }
          return Text('Loading...');
        }
        final String contentBase64 = base64Encode(
          const Utf8Encoder().convert(
            kNavigationExamplePage
                .replaceFirst('QUILL_JS', snapshot.data[_js])
                .replaceFirst('QUILL_CSS', snapshot.data[_css]),
          ),
        );
        return WebView(
          initialUrl: 'data:text/html;base64,$contentBase64',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          javascriptChannels: <JavascriptChannel>[
            //_toasterJavascriptChannel(context),
          ].toSet(),
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('data:text/html;')) {
              return NavigationDecision.navigate;
            }
            if (request.url.startsWith('https://quilljs.com')) {
              return NavigationDecision.navigate;
            }
            Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('navigation blocked')),
            );
            return NavigationDecision.prevent;
          },
          onPageStarted: (String url) {
            print('Page started loading');
          },
          onPageFinished: (String url) {
            print('Page finished loading');
          },
          gestureNavigationEnabled: true,
        );
      },
    );
  }
}

const String kNavigationExamplePage = '''
<!DOCTYPE html><html><body>
<style type="text/css">QUILL_CSS</style>

<!-- Create the editor container -->
<div id="editor">
  <p>Hello World!</p>
  <p>Some initial <strong>bold</strong> text</p>
  <p><br></p>
</div>

<script>QUILL_JS</script>
<script>
  var quill = new Quill('#editor', {
    theme: 'snow'
  });
</script>
</body></html>
''';
