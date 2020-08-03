///
//  Generated code. Do not modify.
//  source: pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Mask extends $pb.ProtobufEnum {
  static const Mask UnspecifiedMask = Mask._(0, 'UnspecifiedMask');
  static const Mask IdsMask = Mask._(1, 'IdsMask');
  static const Mask RefsMask = Mask._(2, 'RefsMask');
  static const Mask TopicsMask = Mask._(3, 'TopicsMask');
  static const Mask NamesMask = Mask._(4, 'NamesMask');
  static const Mask OccurrencesMask = Mask._(5, 'OccurrencesMask');
  static const Mask ValueMask = Mask._(6, 'ValueMask');
  static const Mask ParentMask = Mask._(7, 'ParentMask');

  static const $core.List<Mask> values = <Mask> [
    UnspecifiedMask,
    IdsMask,
    RefsMask,
    TopicsMask,
    NamesMask,
    OccurrencesMask,
    ValueMask,
    ParentMask,
  ];

  static final $core.Map<$core.int, Mask> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Mask valueOf($core.int value) => _byValue[value];

  const Mask._($core.int v, $core.String n) : super(v, n);
}

class RefType extends $pb.ProtobufEnum {
  static const RefType UnspecifiedRefType = RefType._(0, 'UnspecifiedRefType');
  static const RefType ItemIdentifier = RefType._(1, 'ItemIdentifier');
  static const RefType SubjectIdentifier = RefType._(2, 'SubjectIdentifier');
  static const RefType SubjectLocator = RefType._(3, 'SubjectLocator');

  static const $core.List<RefType> values = <RefType> [
    UnspecifiedRefType,
    ItemIdentifier,
    SubjectIdentifier,
    SubjectLocator,
  ];

  static final $core.Map<$core.int, RefType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RefType valueOf($core.int value) => _byValue[value];

  const RefType._($core.int v, $core.String n) : super(v, n);
}

class ItemType extends $pb.ProtobufEnum {
  static const ItemType UnspecifiedItem = ItemType._(0, 'UnspecifiedItem');
  static const ItemType LibraryItem = ItemType._(1, 'LibraryItem');
  static const ItemType TopicMapItem = ItemType._(2, 'TopicMapItem');
  static const ItemType TopicItem = ItemType._(3, 'TopicItem');
  static const ItemType NameItem = ItemType._(4, 'NameItem');
  static const ItemType OccurrenceItem = ItemType._(6, 'OccurrenceItem');

  static const $core.List<ItemType> values = <ItemType> [
    UnspecifiedItem,
    LibraryItem,
    TopicMapItem,
    TopicItem,
    NameItem,
    OccurrenceItem,
  ];

  static final $core.Map<$core.int, ItemType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ItemType valueOf($core.int value) => _byValue[value];

  const ItemType._($core.int v, $core.String n) : super(v, n);
}

class Orderable extends $pb.ProtobufEnum {
  static const Orderable OrderableUnspecified = Orderable._(0, 'OrderableUnspecified');
  static const Orderable OrderableNames = Orderable._(1, 'OrderableNames');
  static const Orderable OrderableOccurrences = Orderable._(2, 'OrderableOccurrences');

  static const $core.List<Orderable> values = <Orderable> [
    OrderableUnspecified,
    OrderableNames,
    OrderableOccurrences,
  ];

  static final $core.Map<$core.int, Orderable> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Orderable valueOf($core.int value) => _byValue[value];

  const Orderable._($core.int v, $core.String n) : super(v, n);
}

