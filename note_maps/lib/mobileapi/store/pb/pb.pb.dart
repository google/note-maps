///
//  Generated code. Do not modify.
//  source: store/pb/pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class TopicMap extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('TopicMap')
    ..a<Int64>(1, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Topic>(2, 'topic', $pb.PbFieldType.OM, Topic.getDefault, Topic.create)
    ..aOB(3, 'inTrash')
    ..hasRequiredFields = false
  ;

  TopicMap._() : super();
  factory TopicMap() => create();
  factory TopicMap.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TopicMap.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  TopicMap clone() => TopicMap()..mergeFromMessage(this);
  TopicMap copyWith(void Function(TopicMap) updates) => super.copyWith((message) => updates(message as TopicMap));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TopicMap create() => TopicMap._();
  TopicMap createEmptyInstance() => create();
  static $pb.PbList<TopicMap> createRepeated() => $pb.PbList<TopicMap>();
  static TopicMap getDefault() => _defaultInstance ??= create()..freeze();
  static TopicMap _defaultInstance;

  Int64 get id => $_getI64(0);
  set id(Int64 v) { $_setInt64(0, v); }
  $core.bool hasId() => $_has(0);
  void clearId() => clearField(1);

  Topic get topic => $_getN(1);
  set topic(Topic v) { setField(2, v); }
  $core.bool hasTopic() => $_has(1);
  void clearTopic() => clearField(2);

  $core.bool get inTrash => $_get(2, false);
  set inTrash($core.bool v) { $_setBool(2, v); }
  $core.bool hasInTrash() => $_has(2);
  void clearInTrash() => clearField(3);
}

class Topic extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Topic')
    ..a<Int64>(1, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..pc<Name>(3, 'names', $pb.PbFieldType.PM,Name.create)
    ..pc<Occurrence>(4, 'occurrences', $pb.PbFieldType.PM,Occurrence.create)
    ..hasRequiredFields = false
  ;

  Topic._() : super();
  factory Topic() => create();
  factory Topic.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Topic.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Topic clone() => Topic()..mergeFromMessage(this);
  Topic copyWith(void Function(Topic) updates) => super.copyWith((message) => updates(message as Topic));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Topic create() => Topic._();
  Topic createEmptyInstance() => create();
  static $pb.PbList<Topic> createRepeated() => $pb.PbList<Topic>();
  static Topic getDefault() => _defaultInstance ??= create()..freeze();
  static Topic _defaultInstance;

  Int64 get id => $_getI64(0);
  set id(Int64 v) { $_setInt64(0, v); }
  $core.bool hasId() => $_has(0);
  void clearId() => clearField(1);

  Int64 get topicMapId => $_getI64(1);
  set topicMapId(Int64 v) { $_setInt64(1, v); }
  $core.bool hasTopicMapId() => $_has(1);
  void clearTopicMapId() => clearField(2);

  $core.List<Name> get names => $_getList(2);

  $core.List<Occurrence> get occurrences => $_getList(3);
}

class Name extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Name')
    ..a<Int64>(1, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'parentId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..aOS(3, 'value')
    ..hasRequiredFields = false
  ;

  Name._() : super();
  factory Name() => create();
  factory Name.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Name.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Name clone() => Name()..mergeFromMessage(this);
  Name copyWith(void Function(Name) updates) => super.copyWith((message) => updates(message as Name));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Name create() => Name._();
  Name createEmptyInstance() => create();
  static $pb.PbList<Name> createRepeated() => $pb.PbList<Name>();
  static Name getDefault() => _defaultInstance ??= create()..freeze();
  static Name _defaultInstance;

  Int64 get id => $_getI64(0);
  set id(Int64 v) { $_setInt64(0, v); }
  $core.bool hasId() => $_has(0);
  void clearId() => clearField(1);

  Int64 get parentId => $_getI64(1);
  set parentId(Int64 v) { $_setInt64(1, v); }
  $core.bool hasParentId() => $_has(1);
  void clearParentId() => clearField(2);

  $core.String get value => $_getS(2, '');
  set value($core.String v) { $_setString(2, v); }
  $core.bool hasValue() => $_has(2);
  void clearValue() => clearField(3);
}

class Occurrence extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Occurrence')
    ..a<Int64>(1, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'parentId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..aOS(3, 'value')
    ..hasRequiredFields = false
  ;

  Occurrence._() : super();
  factory Occurrence() => create();
  factory Occurrence.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Occurrence.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Occurrence clone() => Occurrence()..mergeFromMessage(this);
  Occurrence copyWith(void Function(Occurrence) updates) => super.copyWith((message) => updates(message as Occurrence));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Occurrence create() => Occurrence._();
  Occurrence createEmptyInstance() => create();
  static $pb.PbList<Occurrence> createRepeated() => $pb.PbList<Occurrence>();
  static Occurrence getDefault() => _defaultInstance ??= create()..freeze();
  static Occurrence _defaultInstance;

  Int64 get id => $_getI64(0);
  set id(Int64 v) { $_setInt64(0, v); }
  $core.bool hasId() => $_has(0);
  void clearId() => clearField(1);

  Int64 get parentId => $_getI64(1);
  set parentId(Int64 v) { $_setInt64(1, v); }
  $core.bool hasParentId() => $_has(1);
  void clearParentId() => clearField(2);

  $core.String get value => $_getS(2, '');
  set value($core.String v) { $_setString(2, v); }
  $core.bool hasValue() => $_has(2);
  void clearValue() => clearField(3);
}

class GetTopicMapsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('GetTopicMapsRequest')
    ..aOB(1, 'inTrash')
    ..hasRequiredFields = false
  ;

  GetTopicMapsRequest._() : super();
  factory GetTopicMapsRequest() => create();
  factory GetTopicMapsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTopicMapsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  GetTopicMapsRequest clone() => GetTopicMapsRequest()..mergeFromMessage(this);
  GetTopicMapsRequest copyWith(void Function(GetTopicMapsRequest) updates) => super.copyWith((message) => updates(message as GetTopicMapsRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTopicMapsRequest create() => GetTopicMapsRequest._();
  GetTopicMapsRequest createEmptyInstance() => create();
  static $pb.PbList<GetTopicMapsRequest> createRepeated() => $pb.PbList<GetTopicMapsRequest>();
  static GetTopicMapsRequest getDefault() => _defaultInstance ??= create()..freeze();
  static GetTopicMapsRequest _defaultInstance;

  $core.bool get inTrash => $_get(0, false);
  set inTrash($core.bool v) { $_setBool(0, v); }
  $core.bool hasInTrash() => $_has(0);
  void clearInTrash() => clearField(1);
}

class GetTopicMapsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('GetTopicMapsResponse')
    ..pc<TopicMap>(1, 'topicMaps', $pb.PbFieldType.PM,TopicMap.create)
    ..hasRequiredFields = false
  ;

  GetTopicMapsResponse._() : super();
  factory GetTopicMapsResponse() => create();
  factory GetTopicMapsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTopicMapsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  GetTopicMapsResponse clone() => GetTopicMapsResponse()..mergeFromMessage(this);
  GetTopicMapsResponse copyWith(void Function(GetTopicMapsResponse) updates) => super.copyWith((message) => updates(message as GetTopicMapsResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTopicMapsResponse create() => GetTopicMapsResponse._();
  GetTopicMapsResponse createEmptyInstance() => create();
  static $pb.PbList<GetTopicMapsResponse> createRepeated() => $pb.PbList<GetTopicMapsResponse>();
  static GetTopicMapsResponse getDefault() => _defaultInstance ??= create()..freeze();
  static GetTopicMapsResponse _defaultInstance;

  $core.List<TopicMap> get topicMaps => $_getList(0);
}

class CreateTopicMapRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CreateTopicMapRequest')
    ..hasRequiredFields = false
  ;

  CreateTopicMapRequest._() : super();
  factory CreateTopicMapRequest() => create();
  factory CreateTopicMapRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateTopicMapRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  CreateTopicMapRequest clone() => CreateTopicMapRequest()..mergeFromMessage(this);
  CreateTopicMapRequest copyWith(void Function(CreateTopicMapRequest) updates) => super.copyWith((message) => updates(message as CreateTopicMapRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateTopicMapRequest create() => CreateTopicMapRequest._();
  CreateTopicMapRequest createEmptyInstance() => create();
  static $pb.PbList<CreateTopicMapRequest> createRepeated() => $pb.PbList<CreateTopicMapRequest>();
  static CreateTopicMapRequest getDefault() => _defaultInstance ??= create()..freeze();
  static CreateTopicMapRequest _defaultInstance;
}

class CreateTopicMapResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CreateTopicMapResponse')
    ..a<TopicMap>(1, 'topicMap', $pb.PbFieldType.OM, TopicMap.getDefault, TopicMap.create)
    ..hasRequiredFields = false
  ;

  CreateTopicMapResponse._() : super();
  factory CreateTopicMapResponse() => create();
  factory CreateTopicMapResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateTopicMapResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  CreateTopicMapResponse clone() => CreateTopicMapResponse()..mergeFromMessage(this);
  CreateTopicMapResponse copyWith(void Function(CreateTopicMapResponse) updates) => super.copyWith((message) => updates(message as CreateTopicMapResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateTopicMapResponse create() => CreateTopicMapResponse._();
  CreateTopicMapResponse createEmptyInstance() => create();
  static $pb.PbList<CreateTopicMapResponse> createRepeated() => $pb.PbList<CreateTopicMapResponse>();
  static CreateTopicMapResponse getDefault() => _defaultInstance ??= create()..freeze();
  static CreateTopicMapResponse _defaultInstance;

  TopicMap get topicMap => $_getN(0);
  set topicMap(TopicMap v) { setField(1, v); }
  $core.bool hasTopicMap() => $_has(0);
  void clearTopicMap() => clearField(1);
}

class DeleteTopicMapRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeleteTopicMapRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..aOB(2, 'fullyDelete')
    ..hasRequiredFields = false
  ;

  DeleteTopicMapRequest._() : super();
  factory DeleteTopicMapRequest() => create();
  factory DeleteTopicMapRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteTopicMapRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  DeleteTopicMapRequest clone() => DeleteTopicMapRequest()..mergeFromMessage(this);
  DeleteTopicMapRequest copyWith(void Function(DeleteTopicMapRequest) updates) => super.copyWith((message) => updates(message as DeleteTopicMapRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteTopicMapRequest create() => DeleteTopicMapRequest._();
  DeleteTopicMapRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteTopicMapRequest> createRepeated() => $pb.PbList<DeleteTopicMapRequest>();
  static DeleteTopicMapRequest getDefault() => _defaultInstance ??= create()..freeze();
  static DeleteTopicMapRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  $core.bool get fullyDelete => $_get(1, false);
  set fullyDelete($core.bool v) { $_setBool(1, v); }
  $core.bool hasFullyDelete() => $_has(1);
  void clearFullyDelete() => clearField(2);
}

class DeleteTopicMapResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeleteTopicMapResponse')
    ..hasRequiredFields = false
  ;

  DeleteTopicMapResponse._() : super();
  factory DeleteTopicMapResponse() => create();
  factory DeleteTopicMapResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteTopicMapResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  DeleteTopicMapResponse clone() => DeleteTopicMapResponse()..mergeFromMessage(this);
  DeleteTopicMapResponse copyWith(void Function(DeleteTopicMapResponse) updates) => super.copyWith((message) => updates(message as DeleteTopicMapResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteTopicMapResponse create() => DeleteTopicMapResponse._();
  DeleteTopicMapResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteTopicMapResponse> createRepeated() => $pb.PbList<DeleteTopicMapResponse>();
  static DeleteTopicMapResponse getDefault() => _defaultInstance ??= create()..freeze();
  static DeleteTopicMapResponse _defaultInstance;
}

class RestoreTopicMapRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('RestoreTopicMapRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..hasRequiredFields = false
  ;

  RestoreTopicMapRequest._() : super();
  factory RestoreTopicMapRequest() => create();
  factory RestoreTopicMapRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RestoreTopicMapRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  RestoreTopicMapRequest clone() => RestoreTopicMapRequest()..mergeFromMessage(this);
  RestoreTopicMapRequest copyWith(void Function(RestoreTopicMapRequest) updates) => super.copyWith((message) => updates(message as RestoreTopicMapRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RestoreTopicMapRequest create() => RestoreTopicMapRequest._();
  RestoreTopicMapRequest createEmptyInstance() => create();
  static $pb.PbList<RestoreTopicMapRequest> createRepeated() => $pb.PbList<RestoreTopicMapRequest>();
  static RestoreTopicMapRequest getDefault() => _defaultInstance ??= create()..freeze();
  static RestoreTopicMapRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);
}

class RestoreTopicMapResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('RestoreTopicMapResponse')
    ..hasRequiredFields = false
  ;

  RestoreTopicMapResponse._() : super();
  factory RestoreTopicMapResponse() => create();
  factory RestoreTopicMapResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RestoreTopicMapResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  RestoreTopicMapResponse clone() => RestoreTopicMapResponse()..mergeFromMessage(this);
  RestoreTopicMapResponse copyWith(void Function(RestoreTopicMapResponse) updates) => super.copyWith((message) => updates(message as RestoreTopicMapResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RestoreTopicMapResponse create() => RestoreTopicMapResponse._();
  RestoreTopicMapResponse createEmptyInstance() => create();
  static $pb.PbList<RestoreTopicMapResponse> createRepeated() => $pb.PbList<RestoreTopicMapResponse>();
  static RestoreTopicMapResponse getDefault() => _defaultInstance ??= create()..freeze();
  static RestoreTopicMapResponse _defaultInstance;
}

