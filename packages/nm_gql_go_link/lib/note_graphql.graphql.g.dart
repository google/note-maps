// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_graphql.graphql.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteStatus$Query$Status _$NoteStatus$Query$StatusFromJson(
    Map<String, dynamic> json) {
  return NoteStatus$Query$Status()..summary = json['summary'] as String;
}

Map<String, dynamic> _$NoteStatus$Query$StatusToJson(
        NoteStatus$Query$Status instance) =>
    <String, dynamic>{
      'summary': instance.summary,
    };

NoteStatus$Query _$NoteStatus$QueryFromJson(Map<String, dynamic> json) {
  return NoteStatus$Query()
    ..status = json['status'] == null
        ? null
        : NoteStatus$Query$Status.fromJson(
            json['status'] as Map<String, dynamic>);
}

Map<String, dynamic> _$NoteStatus$QueryToJson(NoteStatus$Query instance) =>
    <String, dynamic>{
      'status': instance.status?.toJson(),
    };
