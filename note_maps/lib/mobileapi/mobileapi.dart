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

import 'dart:typed_data' show Uint8List;
import 'package:flutter/services.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'store/pb/pb.pb.dart';
import 'store/pb/pb.pbenum.dart';
import 'store/pb/pb.pbjson.dart';

export 'store/pb/pb.pb.dart' show TopicMap;
export 'store/pb/pb.pb.dart' show Topic;
export 'store/pb/pb.pb.dart' show Name;
export 'store/pb/pb.pb.dart' show Occurrence;
export 'store/pb/pb.pb.dart' show GetTopicMapsRequest;
export 'store/pb/pb.pb.dart' show GetTopicMapsResponse;

class QueryApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/query');

  Future<Uint8List> getRawResponse(
      String method, $pb.GeneratedMessage request) async {
    final Uint8List rawRequest = request.writeToBuffer();
    return await channel.invokeMethod(method, {
      request: rawRequest,
    });
  }

  Future<GetTopicMapsResponse> getTopicMaps(GetTopicMapsRequest request) async {
    return GetTopicMapsResponse.fromBuffer(
        await getRawResponse('GetTopicMaps', request));
  }
}

class CommandApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/command');
}
