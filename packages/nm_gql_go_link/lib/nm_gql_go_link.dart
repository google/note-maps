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
import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

class NmGqlGoLink extends Link {
  static const MethodChannel _channel = const MethodChannel('nm_gql_go_link');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get goVersion async {
    final String version = await _channel.invokeMethod('getGoVersion');
    return version;
  }

  @override
  Stream<Response> request(
    Request request, [
    NextLink forward,
  ]) async* {
    final Uint8List rawRequest = utf8.encode(jsonEncode(request));
    final Uint8List rawResponse = await _channel.invokeMethod("request", {
      "request": rawRequest,
    });
    yield jsonDecode(utf8.decode(rawResponse));
  }
}
