// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_graphql.graphql.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteSimpleQuery$Query _$NoteSimpleQuery$QueryFromJson(
    Map<String, dynamic> json) {
  return NoteSimpleQuery$Query()..todos = json['todos'] as List;
}

Map<String, dynamic> _$NoteSimpleQuery$QueryToJson(
        NoteSimpleQuery$Query instance) =>
    <String, dynamic>{
      'todos': instance.todos,
    };
