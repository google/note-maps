///
//  Generated code. Do not modify.
//  source: pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'pb.pbenum.dart';

export 'pb.pbenum.dart';

class Library extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Library', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, 'topicMapIds', $pb.PbFieldType.PU6)
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
  @$core.pragma('dart2js:noInline')
  static Library getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Library>(create);
  static Library _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get topicMapIds => $_getList(0);
}

class TopicMap extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('TopicMap', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Topic>(2, 'topic', subBuilder: Topic.create)
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
  @$core.pragma('dart2js:noInline')
  static TopicMap getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TopicMap>(create);
  static TopicMap _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  Topic get topic => $_getN(1);
  @$pb.TagNumber(2)
  set topic(Topic v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearTopic() => clearField(2);
  @$pb.TagNumber(2)
  Topic ensureTopic() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get inTrash => $_getBF(2);
  @$pb.TagNumber(3)
  set inTrash($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasInTrash() => $_has(2);
  @$pb.TagNumber(3)
  void clearInTrash() => clearField(3);
}

class Topic extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Topic', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<Name>(3, 'names', $pb.PbFieldType.PM, subBuilder: Name.create)
    ..pc<Occurrence>(4, 'occurrences', $pb.PbFieldType.PM, subBuilder: Occurrence.create)
    ..p<$fixnum.Int64>(5, 'nameIds', $pb.PbFieldType.PU6)
    ..p<$fixnum.Int64>(6, 'occurrenceIds', $pb.PbFieldType.PU6)
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
  @$core.pragma('dart2js:noInline')
  static Topic getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Topic>(create);
  static Topic _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<Name> get names => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<Occurrence> get occurrences => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$fixnum.Int64> get nameIds => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$fixnum.Int64> get occurrenceIds => $_getList(5);
}

class Name extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Name', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'parentId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
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
  @$core.pragma('dart2js:noInline')
  static Name getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Name>(create);
  static Name _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get parentId => $_getI64(1);
  @$pb.TagNumber(2)
  set parentId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get id => $_getI64(2);
  @$pb.TagNumber(3)
  set id($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get value => $_getSZ(3);
  @$pb.TagNumber(4)
  set value($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => clearField(4);
}

class Occurrence extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Occurrence', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'parentId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
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
  @$core.pragma('dart2js:noInline')
  static Occurrence getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Occurrence>(create);
  static Occurrence _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get parentId => $_getI64(1);
  @$pb.TagNumber(2)
  set parentId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get id => $_getI64(2);
  @$pb.TagNumber(3)
  set id($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get value => $_getSZ(3);
  @$pb.TagNumber(4)
  set value($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => clearField(4);
}

class TupleSequence extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('TupleSequence', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<Tuple>(1, 'tuples', $pb.PbFieldType.PM, subBuilder: Tuple.create)
    ..hasRequiredFields = false
  ;

  TupleSequence._() : super();
  factory TupleSequence() => create();
  factory TupleSequence.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TupleSequence.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  TupleSequence clone() => TupleSequence()..mergeFromMessage(this);
  TupleSequence copyWith(void Function(TupleSequence) updates) => super.copyWith((message) => updates(message as TupleSequence));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TupleSequence create() => TupleSequence._();
  TupleSequence createEmptyInstance() => create();
  static $pb.PbList<TupleSequence> createRepeated() => $pb.PbList<TupleSequence>();
  @$core.pragma('dart2js:noInline')
  static TupleSequence getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TupleSequence>(create);
  static TupleSequence _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Tuple> get tuples => $_getList(0);
}

class Tuple extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Tuple', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<AnyItem>(1, 'items', $pb.PbFieldType.PM, subBuilder: AnyItem.create)
    ..hasRequiredFields = false
  ;

  Tuple._() : super();
  factory Tuple() => create();
  factory Tuple.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Tuple.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Tuple clone() => Tuple()..mergeFromMessage(this);
  Tuple copyWith(void Function(Tuple) updates) => super.copyWith((message) => updates(message as Tuple));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Tuple create() => Tuple._();
  Tuple createEmptyInstance() => create();
  static $pb.PbList<Tuple> createRepeated() => $pb.PbList<Tuple>();
  @$core.pragma('dart2js:noInline')
  static Tuple getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Tuple>(create);
  static Tuple _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<AnyItem> get items => $_getList(0);
}

class AnyItem extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('AnyItem', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'itemId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
    ..pc<Ref>(4, 'refs', $pb.PbFieldType.PM, subBuilder: Ref.create)
    ..p<$fixnum.Int64>(5, 'nameIds', $pb.PbFieldType.PU6)
    ..pc<AnyItem>(6, 'names', $pb.PbFieldType.PM, subBuilder: AnyItem.create)
    ..p<$fixnum.Int64>(7, 'occurrenceIds', $pb.PbFieldType.PU6)
    ..pc<AnyItem>(8, 'occurrences', $pb.PbFieldType.PM, subBuilder: AnyItem.create)
    ..aOS(9, 'value')
    ..aOM<Ref>(10, 'typeRef', subBuilder: Ref.create)
    ..aOM<Ref>(11, 'playerRef', subBuilder: Ref.create)
    ..p<$fixnum.Int64>(12, 'roleIds', $pb.PbFieldType.PU6)
    ..pc<AnyItem>(13, 'roles', $pb.PbFieldType.PM, subBuilder: AnyItem.create)
    ..hasRequiredFields = false
  ;

  AnyItem._() : super();
  factory AnyItem() => create();
  factory AnyItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AnyItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  AnyItem clone() => AnyItem()..mergeFromMessage(this);
  AnyItem copyWith(void Function(AnyItem) updates) => super.copyWith((message) => updates(message as AnyItem));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AnyItem create() => AnyItem._();
  AnyItem createEmptyInstance() => create();
  static $pb.PbList<AnyItem> createRepeated() => $pb.PbList<AnyItem>();
  @$core.pragma('dart2js:noInline')
  static AnyItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AnyItem>(create);
  static AnyItem _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get itemId => $_getI64(1);
  @$pb.TagNumber(2)
  set itemId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasItemId() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemId() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<Ref> get refs => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$fixnum.Int64> get nameIds => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<AnyItem> get names => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<$fixnum.Int64> get occurrenceIds => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<AnyItem> get occurrences => $_getList(7);

  @$pb.TagNumber(9)
  $core.String get value => $_getSZ(8);
  @$pb.TagNumber(9)
  set value($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasValue() => $_has(8);
  @$pb.TagNumber(9)
  void clearValue() => clearField(9);

  @$pb.TagNumber(10)
  Ref get typeRef => $_getN(9);
  @$pb.TagNumber(10)
  set typeRef(Ref v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasTypeRef() => $_has(9);
  @$pb.TagNumber(10)
  void clearTypeRef() => clearField(10);
  @$pb.TagNumber(10)
  Ref ensureTypeRef() => $_ensure(9);

  @$pb.TagNumber(11)
  Ref get playerRef => $_getN(10);
  @$pb.TagNumber(11)
  set playerRef(Ref v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasPlayerRef() => $_has(10);
  @$pb.TagNumber(11)
  void clearPlayerRef() => clearField(11);
  @$pb.TagNumber(11)
  Ref ensurePlayerRef() => $_ensure(10);

  @$pb.TagNumber(12)
  $core.List<$fixnum.Int64> get roleIds => $_getList(11);

  @$pb.TagNumber(13)
  $core.List<AnyItem> get roles => $_getList(12);
}

class Ref extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Ref', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..e<RefType>(1, 'type', $pb.PbFieldType.OE, defaultOrMaker: RefType.UnspecifiedRefType, valueOf: RefType.valueOf, enumValues: RefType.values)
    ..aOS(2, 'iri')
    ..hasRequiredFields = false
  ;

  Ref._() : super();
  factory Ref() => create();
  factory Ref.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Ref.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Ref clone() => Ref()..mergeFromMessage(this);
  Ref copyWith(void Function(Ref) updates) => super.copyWith((message) => updates(message as Ref));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Ref create() => Ref._();
  Ref createEmptyInstance() => create();
  static $pb.PbList<Ref> createRepeated() => $pb.PbList<Ref>();
  @$core.pragma('dart2js:noInline')
  static Ref getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ref>(create);
  static Ref _defaultInstance;

  @$pb.TagNumber(1)
  RefType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(RefType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get iri => $_getSZ(1);
  @$pb.TagNumber(2)
  set iri($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIri() => $_has(1);
  @$pb.TagNumber(2)
  void clearIri() => clearField(2);
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Item', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 6])
    ..aOM<Library>(1, 'library', subBuilder: Library.create)
    ..aOM<TopicMap>(2, 'topicMap', subBuilder: TopicMap.create)
    ..aOM<Topic>(3, 'topic', subBuilder: Topic.create)
    ..aOM<Name>(4, 'name', subBuilder: Name.create)
    ..aOM<Occurrence>(6, 'occurrence', subBuilder: Occurrence.create)
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
  @$core.pragma('dart2js:noInline')
  static Item getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Item>(create);
  static Item _defaultInstance;

  Item_Specific whichSpecific() => _Item_SpecificByTag[$_whichOneof(0)];
  void clearSpecific() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Library get library => $_getN(0);
  @$pb.TagNumber(1)
  set library(Library v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLibrary() => $_has(0);
  @$pb.TagNumber(1)
  void clearLibrary() => clearField(1);
  @$pb.TagNumber(1)
  Library ensureLibrary() => $_ensure(0);

  @$pb.TagNumber(2)
  TopicMap get topicMap => $_getN(1);
  @$pb.TagNumber(2)
  set topicMap(TopicMap v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTopicMap() => $_has(1);
  @$pb.TagNumber(2)
  void clearTopicMap() => clearField(2);
  @$pb.TagNumber(2)
  TopicMap ensureTopicMap() => $_ensure(1);

  @$pb.TagNumber(3)
  Topic get topic => $_getN(2);
  @$pb.TagNumber(3)
  set topic(Topic v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearTopic() => clearField(3);
  @$pb.TagNumber(3)
  Topic ensureTopic() => $_ensure(2);

  @$pb.TagNumber(4)
  Name get name => $_getN(3);
  @$pb.TagNumber(4)
  set name(Name v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);
  @$pb.TagNumber(4)
  Name ensureName() => $_ensure(3);

  @$pb.TagNumber(6)
  Occurrence get occurrence => $_getN(4);
  @$pb.TagNumber(6)
  set occurrence(Occurrence v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasOccurrence() => $_has(4);
  @$pb.TagNumber(6)
  void clearOccurrence() => clearField(6);
  @$pb.TagNumber(6)
  Occurrence ensureOccurrence() => $_ensure(4);
}

class LoadRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('LoadRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
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
  @$core.pragma('dart2js:noInline')
  static LoadRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoadRequest>(create);
  static LoadRequest _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);
}

class LoadResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('LoadResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..aOM<Item>(1, 'item', subBuilder: Item.create)
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
  @$core.pragma('dart2js:noInline')
  static LoadResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoadResponse>(create);
  static LoadResponse _defaultInstance;

  @$pb.TagNumber(1)
  Item get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(Item v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => clearField(1);
  @$pb.TagNumber(1)
  Item ensureItem() => $_ensure(0);
}

class SearchRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('SearchRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, 'topicMapIds', $pb.PbFieldType.PU6)
    ..aOS(2, 'tmql')
    ..hasRequiredFields = false
  ;

  SearchRequest._() : super();
  factory SearchRequest() => create();
  factory SearchRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  SearchRequest clone() => SearchRequest()..mergeFromMessage(this);
  SearchRequest copyWith(void Function(SearchRequest) updates) => super.copyWith((message) => updates(message as SearchRequest));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  SearchRequest createEmptyInstance() => create();
  static $pb.PbList<SearchRequest> createRepeated() => $pb.PbList<SearchRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get topicMapIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get tmql => $_getSZ(1);
  @$pb.TagNumber(2)
  set tmql($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTmql() => $_has(1);
  @$pb.TagNumber(2)
  void clearTmql() => clearField(2);
}

class SearchResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('SearchResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<Item>(1, 'items', $pb.PbFieldType.PM, subBuilder: Item.create)
    ..a<$fixnum.Int64>(2, 'count', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, 'offset', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  SearchResponse._() : super();
  factory SearchResponse() => create();
  factory SearchResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  SearchResponse clone() => SearchResponse()..mergeFromMessage(this);
  SearchResponse copyWith(void Function(SearchResponse) updates) => super.copyWith((message) => updates(message as SearchResponse));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  SearchResponse createEmptyInstance() => create();
  static $pb.PbList<SearchResponse> createRepeated() => $pb.PbList<SearchResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Item> get items => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => clearField(3);
}

class QueryRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('QueryRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<LoadRequest>(1, 'loadRequests', $pb.PbFieldType.PM, subBuilder: LoadRequest.create)
    ..pc<SearchRequest>(2, 'searchRequests', $pb.PbFieldType.PM, subBuilder: SearchRequest.create)
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
  @$core.pragma('dart2js:noInline')
  static QueryRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryRequest>(create);
  static QueryRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<LoadRequest> get loadRequests => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<SearchRequest> get searchRequests => $_getList(1);
}

class QueryResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('QueryResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<LoadResponse>(1, 'loadResponses', $pb.PbFieldType.PM, subBuilder: LoadResponse.create)
    ..pc<SearchResponse>(2, 'searchResponses', $pb.PbFieldType.PM, subBuilder: SearchResponse.create)
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
  @$core.pragma('dart2js:noInline')
  static QueryResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryResponse>(create);
  static QueryResponse _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<LoadResponse> get loadResponses => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<SearchResponse> get searchResponses => $_getList(1);
}

class CreationRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CreationRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'parent', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
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
  @$core.pragma('dart2js:noInline')
  static CreationRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreationRequest>(create);
  static CreationRequest _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get parent => $_getI64(1);
  @$pb.TagNumber(2)
  set parent($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearParent() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);
}

class UpdateOrderRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateOrderRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<Orderable>(4, 'orderable', $pb.PbFieldType.OE, defaultOrMaker: Orderable.OrderableUnspecified, valueOf: Orderable.valueOf, enumValues: Orderable.values)
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
  @$core.pragma('dart2js:noInline')
  static UpdateOrderRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateOrderRequest>(create);
  static UpdateOrderRequest _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(4)
  Orderable get orderable => $_getN(2);
  @$pb.TagNumber(4)
  set orderable(Orderable v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasOrderable() => $_has(2);
  @$pb.TagNumber(4)
  void clearOrderable() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get srcIndices => $_getList(3);

  @$pb.TagNumber(6)
  $core.List<$core.int> get dstIndices => $_getList(4);
}

class UpdateValueRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateValueRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
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
  @$core.pragma('dart2js:noInline')
  static UpdateValueRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateValueRequest>(create);
  static UpdateValueRequest _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get value => $_getSZ(3);
  @$pb.TagNumber(4)
  set value($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => clearField(4);
}

class UpdateResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('UpdateResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Item>(3, 'item', subBuilder: Item.create)
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
  @$core.pragma('dart2js:noInline')
  static UpdateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateResponse>(create);
  static UpdateResponse _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  Item get item => $_getN(2);
  @$pb.TagNumber(3)
  set item(Item v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItem() => $_has(2);
  @$pb.TagNumber(3)
  void clearItem() => clearField(3);
  @$pb.TagNumber(3)
  Item ensureItem() => $_ensure(2);
}

class DeletionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeletionRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
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
  @$core.pragma('dart2js:noInline')
  static DeletionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeletionRequest>(create);
  static DeletionRequest _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);
}

class DeletionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('DeletionResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'topicMapId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<ItemType>(3, 'itemType', $pb.PbFieldType.OE, defaultOrMaker: ItemType.UnspecifiedItem, valueOf: ItemType.valueOf, enumValues: ItemType.values)
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
  @$core.pragma('dart2js:noInline')
  static DeletionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeletionResponse>(create);
  static DeletionResponse _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get topicMapId => $_getI64(0);
  @$pb.TagNumber(1)
  set topicMapId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTopicMapId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopicMapId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(2)
  set id($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  ItemType get itemType => $_getN(2);
  @$pb.TagNumber(3)
  set itemType(ItemType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemType() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemType() => clearField(3);
}

class MutationRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MutationRequest', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<CreationRequest>(1, 'creationRequests', $pb.PbFieldType.PM, subBuilder: CreationRequest.create)
    ..pc<UpdateOrderRequest>(2, 'updateOrderRequests', $pb.PbFieldType.PM, subBuilder: UpdateOrderRequest.create)
    ..pc<UpdateValueRequest>(3, 'updateValueRequests', $pb.PbFieldType.PM, subBuilder: UpdateValueRequest.create)
    ..pc<DeletionRequest>(4, 'deletionRequests', $pb.PbFieldType.PM, subBuilder: DeletionRequest.create)
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
  @$core.pragma('dart2js:noInline')
  static MutationRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MutationRequest>(create);
  static MutationRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<CreationRequest> get creationRequests => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<UpdateOrderRequest> get updateOrderRequests => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<UpdateValueRequest> get updateValueRequests => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<DeletionRequest> get deletionRequests => $_getList(3);
}

class MutationResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MutationResponse', package: const $pb.PackageName('notemaps.tmaps.pb'), createEmptyInstance: create)
    ..pc<UpdateResponse>(1, 'creationResponses', $pb.PbFieldType.PM, subBuilder: UpdateResponse.create)
    ..pc<UpdateResponse>(2, 'updateOrderResponses', $pb.PbFieldType.PM, subBuilder: UpdateResponse.create)
    ..pc<UpdateResponse>(3, 'updateValueResponses', $pb.PbFieldType.PM, subBuilder: UpdateResponse.create)
    ..pc<DeletionResponse>(4, 'deletionResponses', $pb.PbFieldType.PM, subBuilder: DeletionResponse.create)
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
  @$core.pragma('dart2js:noInline')
  static MutationResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MutationResponse>(create);
  static MutationResponse _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<UpdateResponse> get creationResponses => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<UpdateResponse> get updateOrderResponses => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<UpdateResponse> get updateValueResponses => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<DeletionResponse> get deletionResponses => $_getList(3);
}

