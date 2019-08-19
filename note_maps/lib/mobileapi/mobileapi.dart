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
export 'store/pb/pb.pb.dart' show CreateTopicMapRequest;
export 'store/pb/pb.pb.dart' show CreateTopicMapResponse;
export 'store/pb/pb.pb.dart' show DeleteTopicMapRequest;
export 'store/pb/pb.pb.dart' show DeleteTopicMapResponse;
export 'store/pb/pb.pb.dart' show RestoreTopicMapRequest;
export 'store/pb/pb.pb.dart' show RestoreTopicMapResponse;

Future<Uint8List> _getRawResponse(
    MethodChannel channel, String method, $pb.GeneratedMessage request) async {
  final Uint8List rawRequest = request.writeToBuffer();
  final Uint8List rawResponse = await channel.invokeMethod(method, {
    "request": rawRequest,
  });
  return rawResponse ?? Uint8List(0);
}

class QueryApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/query');

  Future<GetTopicMapsResponse> getTopicMaps(GetTopicMapsRequest request) async {
    return GetTopicMapsResponse.fromBuffer(
        await _getRawResponse(channel, 'GetTopicMaps', request));
  }
}

class CommandApi {
  static const channel =
      const MethodChannel('github.com/google/note-maps/command');

  Future<CreateTopicMapResponse> createTopicMap(
      CreateTopicMapRequest request) async {
    return CreateTopicMapResponse.fromBuffer(
        await _getRawResponse(channel, 'CreateTopicMap', request));
  }

  Future<DeleteTopicMapResponse> deleteTopicMap(
      DeleteTopicMapRequest request) async {
    return DeleteTopicMapResponse.fromBuffer(
        await _getRawResponse(channel, 'DeleteTopicMap', request));
  }

  Future<RestoreTopicMapResponse> restoreTopicMap(
      RestoreTopicMapRequest request) async {
    return RestoreTopicMapResponse.fromBuffer(
        await _getRawResponse(channel, 'RestoreTopicMap', request));
  }
}
