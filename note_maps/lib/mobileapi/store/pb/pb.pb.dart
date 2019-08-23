///
//  Generated code. Do not modify.
//  source: store/pb/pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'pb.pbenum.dart';

export 'pb.pbenum.dart';

class Library extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Library')
    ..p<Int64>(1, 'topicMapIds', $pb.PbFieldType.PU6)
    ..hasRequiredFields = false
  ;

  Library._() : super();
  factory Library() => create();
  factory Library.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Library.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Library clone() => Library()..mergeFromMessage(this);
  Library copyWith(void Function(Library) updates) => super.copyWith((message) => updates(message as Library));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Library create() => Library._();
  Library createEmptyInstance() => create();
  static $pb.PbList<Library> createRepeated() => $pb.PbList<Library>();
  static Library getDefault() => _defaultInstance ??= create()..freeze();
  static Library _defaultInstance;

  $core.List<Int64> get topicMapIds => $_getList(0);
}

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
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..pc<Name>(3, 'names', $pb.PbFieldType.PM,Name.create)
    ..pc<Occurrence>(4, 'occurrences', $pb.PbFieldType.PM,Occurrence.create)
    ..p<Int64>(5, 'nameIds', $pb.PbFieldType.PU6)
    ..p<Int64>(6, 'occurrenceIds', $pb.PbFieldType.PU6)
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

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  $core.List<Name> get names => $_getList(2);

  $core.List<Occurrence> get occurrences => $_getList(3);

  $core.List<Int64> get nameIds => $_getList(4);

  $core.List<Int64> get occurrenceIds => $_getList(5);
}

class Name extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Name')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'parentId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(3, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..aOS(4, 'value')
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

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get parentId => $_getI64(1);
  set parentId(Int64 v) { $_setInt64(1, v); }
  $core.bool hasParentId() => $_has(1);
  void clearParentId() => clearField(2);

  Int64 get id => $_getI64(2);
  set id(Int64 v) { $_setInt64(2, v); }
  $core.bool hasId() => $_has(2);
  void clearId() => clearField(3);

  $core.String get value => $_getS(3, '');
  set value($core.String v) { $_setString(3, v); }
  $core.bool hasValue() => $_has(3);
  void clearValue() => clearField(4);
}

class Occurrence extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Occurrence')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'parentId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(3, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..aOS(4, 'value')
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

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get parentId => $_getI64(1);
  set parentId(Int64 v) { $_setInt64(1, v); }
  $core.bool hasParentId() => $_has(1);
  void clearParentId() => clearField(2);

  Int64 get id => $_getI64(2);
  set id(Int64 v) { $_setInt64(2, v); }
  $core.bool hasId() => $_has(2);
  void clearId() => clearField(3);

  $core.String get value => $_getS(3, '');
  set value($core.String v) { $_setString(3, v); }
  $core.bool hasValue() => $_has(3);
  void clearValue() => clearField(4);
}

enum Item_Specific {
  library, 
  topicMap, 
  topic, 
  name, 
  occurrence, 
  notSet
}

class Item extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Item_Specific> _Item_SpecificByTag = {
    1 : Item_Specific.library,
    2 : Item_Specific.topicMap,
    3 : Item_Specific.topic,
    4 : Item_Specific.name,
    6 : Item_Specific.occurrence,
    0 : Item_Specific.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Item')
    ..oo(0, [1, 2, 3, 4, 6])
    ..a<Library>(1, 'library', $pb.PbFieldType.OM, Library.getDefault, Library.create)
    ..a<TopicMap>(2, 'topicMap', $pb.PbFieldType.OM, TopicMap.getDefault, TopicMap.create)
    ..a<Topic>(3, 'topic', $pb.PbFieldType.OM, Topic.getDefault, Topic.create)
    ..a<Name>(4, 'name', $pb.PbFieldType.OM, Name.getDefault, Name.create)
    ..a<Occurrence>(6, 'occurrence', $pb.PbFieldType.OM, Occurrence.getDefault, Occurrence.create)
    ..hasRequiredFields = false
  ;

  Item._() : super();
  factory Item() => create();
  factory Item.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Item.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Item clone() => Item()..mergeFromMessage(this);
  Item copyWith(void Function(Item) updates) => super.copyWith((message) => updates(message as Item));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Item create() => Item._();
  Item createEmptyInstance() => create();
  static $pb.PbList<Item> createRepeated() => $pb.PbList<Item>();
  static Item getDefault() => _defaultInstance ??= create()..freeze();
  static Item _defaultInstance;

  Item_Specific whichSpecific() => _Item_SpecificByTag[$_whichOneof(0)];
  void clearSpecific() => clearField($_whichOneof(0));

  Library get library => $_getN(0);
  set library(Library v) { setField(1, v); }
  $core.bool hasLibrary() => $_has(0);
  void clearLibrary() => clearField(1);

  TopicMap get topicMap => $_getN(1);
  set topicMap(TopicMap v) { setField(2, v); }
  $core.bool hasTopicMap() => $_has(1);
  void clearTopicMap() => clearField(2);

  Topic get topic => $_getN(2);
  set topic(Topic v) { setField(3, v); }
  $core.bool hasTopic() => $_has(2);
  void clearTopic() => clearField(3);

  Name get name => $_getN(3);
  set name(Name v) { setField(4, v); }
  $core.bool hasName() => $_has(3);
  void clearName() => clearField(4);

  Occurrence get occurrence => $_getN(4);
  set occurrence(Occurrence v) { setField(6, v); }
  $core.bool hasOccurrence() => $_has(4);
  void clearOccurrence() => clearField(6);
}

class LoadRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('LoadRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, ItemType.UnspecifiedItem, ItemType.valueOf, ItemType.values)
    ..hasRequiredFields = false
  ;

  LoadRequest._() : super();
  factory LoadRequest() => create();
  factory LoadRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LoadRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  LoadRequest clone() => LoadRequest()..mergeFromMessage(this);
  LoadRequest copyWith(void Function(LoadRequest) updates) => super.copyWith((message) => updates(message as LoadRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LoadRequest create() => LoadRequest._();
  LoadRequest createEmptyInstance() => create();
  static $pb.PbList<LoadRequest> createRepeated() => $pb.PbList<LoadRequest>();
  static LoadRequest getDefault() => _defaultInstance ??= create()..freeze();
  static LoadRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  ItemType get itemType => $_getN(2);
  set itemType(ItemType v) { setField(3, v); }
  $core.bool hasItemType() => $_has(2);
  void clearItemType() => clearField(3);
}

class LoadResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('LoadResponse')
    ..a<Item>(1, 'item', $pb.PbFieldType.OM, Item.getDefault, Item.create)
    ..hasRequiredFields = false
  ;

  LoadResponse._() : super();
  factory LoadResponse() => create();
  factory LoadResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LoadResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  LoadResponse clone() => LoadResponse()..mergeFromMessage(this);
  LoadResponse copyWith(void Function(LoadResponse) updates) => super.copyWith((message) => updates(message as LoadResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LoadResponse create() => LoadResponse._();
  LoadResponse createEmptyInstance() => create();
  static $pb.PbList<LoadResponse> createRepeated() => $pb.PbList<LoadResponse>();
  static LoadResponse getDefault() => _defaultInstance ??= create()..freeze();
  static LoadResponse _defaultInstance;

  Item get item => $_getN(0);
  set item(Item v) { setField(1, v); }
  $core.bool hasItem() => $_has(0);
  void clearItem() => clearField(1);
}

class QueryRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('QueryRequest')
    ..pc<LoadRequest>(1, 'loadRequests', $pb.PbFieldType.PM,LoadRequest.create)
    ..hasRequiredFields = false
  ;

  QueryRequest._() : super();
  factory QueryRequest() => create();
  factory QueryRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  QueryRequest clone() => QueryRequest()..mergeFromMessage(this);
  QueryRequest copyWith(void Function(QueryRequest) updates) => super.copyWith((message) => updates(message as QueryRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryRequest create() => QueryRequest._();
  QueryRequest createEmptyInstance() => create();
  static $pb.PbList<QueryRequest> createRepeated() => $pb.PbList<QueryRequest>();
  static QueryRequest getDefault() => _defaultInstance ??= create()..freeze();
  static QueryRequest _defaultInstance;

  $core.List<LoadRequest> get loadRequests => $_getList(0);
}

class QueryResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('QueryResponse')
    ..pc<LoadResponse>(1, 'loadResponses', $pb.PbFieldType.PM,LoadResponse.create)
    ..hasRequiredFields = false
  ;

  QueryResponse._() : super();
  factory QueryResponse() => create();
  factory QueryResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  QueryResponse clone() => QueryResponse()..mergeFromMessage(this);
  QueryResponse copyWith(void Function(QueryResponse) updates) => super.copyWith((message) => updates(message as QueryResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryResponse create() => QueryResponse._();
  QueryResponse createEmptyInstance() => create();
  static $pb.PbList<QueryResponse> createRepeated() => $pb.PbList<QueryResponse>();
  static QueryResponse getDefault() => _defaultInstance ??= create()..freeze();
  static QueryResponse _defaultInstance;

  $core.List<LoadResponse> get loadResponses => $_getList(0);
}

class CreationRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CreationRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'parent', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, ItemType.UnspecifiedItem, ItemType.valueOf, ItemType.values)
    ..hasRequiredFields = false
  ;

  CreationRequest._() : super();
  factory CreationRequest() => create();
  factory CreationRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreationRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  CreationRequest clone() => CreationRequest()..mergeFromMessage(this);
  CreationRequest copyWith(void Function(CreationRequest) updates) => super.copyWith((message) => updates(message as CreationRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreationRequest create() => CreationRequest._();
  CreationRequest createEmptyInstance() => create();
  static $pb.PbList<CreationRequest> createRepeated() => $pb.PbList<CreationRequest>();
  static CreationRequest getDefault() => _defaultInstance ??= create()..freeze();
  static CreationRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get parent => $_getI64(1);
  set parent(Int64 v) { $_setInt64(1, v); }
  $core.bool hasParent() => $_has(1);
  void clearParent() => clearField(2);

  ItemType get itemType => $_getN(2);
  set itemType(ItemType v) { setField(3, v); }
  $core.bool hasItemType() => $_has(2);
  void clearItemType() => clearField(3);
}

class UpdateOrderRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateOrderRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<Orderable>(4, 'orderable', $pb.PbFieldType.OE, Orderable.OrderableUnspecified, Orderable.valueOf, Orderable.values)
    ..p<$core.int>(5, 'srcIndices', $pb.PbFieldType.PU3)
    ..p<$core.int>(6, 'dstIndices', $pb.PbFieldType.PU3)
    ..hasRequiredFields = false
  ;

  UpdateOrderRequest._() : super();
  factory UpdateOrderRequest() => create();
  factory UpdateOrderRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateOrderRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  UpdateOrderRequest clone() => UpdateOrderRequest()..mergeFromMessage(this);
  UpdateOrderRequest copyWith(void Function(UpdateOrderRequest) updates) => super.copyWith((message) => updates(message as UpdateOrderRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateOrderRequest create() => UpdateOrderRequest._();
  UpdateOrderRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateOrderRequest> createRepeated() => $pb.PbList<UpdateOrderRequest>();
  static UpdateOrderRequest getDefault() => _defaultInstance ??= create()..freeze();
  static UpdateOrderRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  Orderable get orderable => $_getN(2);
  set orderable(Orderable v) { setField(4, v); }
  $core.bool hasOrderable() => $_has(2);
  void clearOrderable() => clearField(4);

  $core.List<$core.int> get srcIndices => $_getList(3);

  $core.List<$core.int> get dstIndices => $_getList(4);
}

class UpdateValueRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateValueRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, ItemType.UnspecifiedItem, ItemType.valueOf, ItemType.values)
    ..aOS(4, 'value')
    ..hasRequiredFields = false
  ;

  UpdateValueRequest._() : super();
  factory UpdateValueRequest() => create();
  factory UpdateValueRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateValueRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  UpdateValueRequest clone() => UpdateValueRequest()..mergeFromMessage(this);
  UpdateValueRequest copyWith(void Function(UpdateValueRequest) updates) => super.copyWith((message) => updates(message as UpdateValueRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateValueRequest create() => UpdateValueRequest._();
  UpdateValueRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateValueRequest> createRepeated() => $pb.PbList<UpdateValueRequest>();
  static UpdateValueRequest getDefault() => _defaultInstance ??= create()..freeze();
  static UpdateValueRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  ItemType get itemType => $_getN(2);
  set itemType(ItemType v) { setField(3, v); }
  $core.bool hasItemType() => $_has(2);
  void clearItemType() => clearField(3);

  $core.String get value => $_getS(3, '');
  set value($core.String v) { $_setString(3, v); }
  $core.bool hasValue() => $_has(3);
  void clearValue() => clearField(4);
}

class UpdateResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateResponse')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Item>(3, 'item', $pb.PbFieldType.OM, Item.getDefault, Item.create)
    ..hasRequiredFields = false
  ;

  UpdateResponse._() : super();
  factory UpdateResponse() => create();
  factory UpdateResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  UpdateResponse clone() => UpdateResponse()..mergeFromMessage(this);
  UpdateResponse copyWith(void Function(UpdateResponse) updates) => super.copyWith((message) => updates(message as UpdateResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateResponse create() => UpdateResponse._();
  UpdateResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateResponse> createRepeated() => $pb.PbList<UpdateResponse>();
  static UpdateResponse getDefault() => _defaultInstance ??= create()..freeze();
  static UpdateResponse _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  Item get item => $_getN(2);
  set item(Item v) { setField(3, v); }
  $core.bool hasItem() => $_has(2);
  void clearItem() => clearField(3);
}

class DeletionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeletionRequest')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, ItemType.UnspecifiedItem, ItemType.valueOf, ItemType.values)
    ..hasRequiredFields = false
  ;

  DeletionRequest._() : super();
  factory DeletionRequest() => create();
  factory DeletionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeletionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  DeletionRequest clone() => DeletionRequest()..mergeFromMessage(this);
  DeletionRequest copyWith(void Function(DeletionRequest) updates) => super.copyWith((message) => updates(message as DeletionRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeletionRequest create() => DeletionRequest._();
  DeletionRequest createEmptyInstance() => create();
  static $pb.PbList<DeletionRequest> createRepeated() => $pb.PbList<DeletionRequest>();
  static DeletionRequest getDefault() => _defaultInstance ??= create()..freeze();
  static DeletionRequest _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  ItemType get itemType => $_getN(2);
  set itemType(ItemType v) { setField(3, v); }
  $core.bool hasItemType() => $_has(2);
  void clearItemType() => clearField(3);
}

class DeletionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeletionResponse')
    ..a<Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, Int64.ZERO)
    ..a<Int64>(2, 'id', $pb.PbFieldType.OU6, Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, ItemType.UnspecifiedItem, ItemType.valueOf, ItemType.values)
    ..hasRequiredFields = false
  ;

  DeletionResponse._() : super();
  factory DeletionResponse() => create();
  factory DeletionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeletionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  DeletionResponse clone() => DeletionResponse()..mergeFromMessage(this);
  DeletionResponse copyWith(void Function(DeletionResponse) updates) => super.copyWith((message) => updates(message as DeletionResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeletionResponse create() => DeletionResponse._();
  DeletionResponse createEmptyInstance() => create();
  static $pb.PbList<DeletionResponse> createRepeated() => $pb.PbList<DeletionResponse>();
  static DeletionResponse getDefault() => _defaultInstance ??= create()..freeze();
  static DeletionResponse _defaultInstance;

  Int64 get topicMapId => $_getI64(0);
  set topicMapId(Int64 v) { $_setInt64(0, v); }
  $core.bool hasTopicMapId() => $_has(0);
  void clearTopicMapId() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) { $_setInt64(1, v); }
  $core.bool hasId() => $_has(1);
  void clearId() => clearField(2);

  ItemType get itemType => $_getN(2);
  set itemType(ItemType v) { setField(3, v); }
  $core.bool hasItemType() => $_has(2);
  void clearItemType() => clearField(3);
}

class MutationRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MutationRequest')
    ..pc<CreationRequest>(1, 'creationRequests', $pb.PbFieldType.PM,CreationRequest.create)
    ..pc<UpdateOrderRequest>(2, 'updateOrderRequests', $pb.PbFieldType.PM,UpdateOrderRequest.create)
    ..pc<UpdateValueRequest>(3, 'updateValueRequests', $pb.PbFieldType.PM,UpdateValueRequest.create)
    ..pc<DeletionRequest>(4, 'deletionRequests', $pb.PbFieldType.PM,DeletionRequest.create)
    ..hasRequiredFields = false
  ;

  MutationRequest._() : super();
  factory MutationRequest() => create();
  factory MutationRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MutationRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MutationRequest clone() => MutationRequest()..mergeFromMessage(this);
  MutationRequest copyWith(void Function(MutationRequest) updates) => super.copyWith((message) => updates(message as MutationRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MutationRequest create() => MutationRequest._();
  MutationRequest createEmptyInstance() => create();
  static $pb.PbList<MutationRequest> createRepeated() => $pb.PbList<MutationRequest>();
  static MutationRequest getDefault() => _defaultInstance ??= create()..freeze();
  static MutationRequest _defaultInstance;

  $core.List<CreationRequest> get creationRequests => $_getList(0);

  $core.List<UpdateOrderRequest> get updateOrderRequests => $_getList(1);

  $core.List<UpdateValueRequest> get updateValueRequests => $_getList(2);

  $core.List<DeletionRequest> get deletionRequests => $_getList(3);
}

class MutationResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MutationResponse')
    ..pc<UpdateResponse>(1, 'creationResponses', $pb.PbFieldType.PM,UpdateResponse.create)
    ..pc<UpdateResponse>(2, 'updateOrderResponses', $pb.PbFieldType.PM,UpdateResponse.create)
    ..pc<UpdateResponse>(3, 'updateValueResponses', $pb.PbFieldType.PM,UpdateResponse.create)
    ..pc<DeletionResponse>(4, 'deletionResponses', $pb.PbFieldType.PM,DeletionResponse.create)
    ..hasRequiredFields = false
  ;

  MutationResponse._() : super();
  factory MutationResponse() => create();
  factory MutationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MutationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MutationResponse clone() => MutationResponse()..mergeFromMessage(this);
  MutationResponse copyWith(void Function(MutationResponse) updates) => super.copyWith((message) => updates(message as MutationResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MutationResponse create() => MutationResponse._();
  MutationResponse createEmptyInstance() => create();
  static $pb.PbList<MutationResponse> createRepeated() => $pb.PbList<MutationResponse>();
  static MutationResponse getDefault() => _defaultInstance ??= create()..freeze();
  static MutationResponse _defaultInstance;

  $core.List<UpdateResponse> get creationResponses => $_getList(0);

  $core.List<UpdateResponse> get updateOrderResponses => $_getList(1);

  $core.List<UpdateResponse> get updateValueResponses => $_getList(2);

  $core.List<DeletionResponse> get deletionResponses => $_getList(3);
}

