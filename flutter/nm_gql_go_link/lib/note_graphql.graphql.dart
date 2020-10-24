// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:meta/meta.dart';
import 'package:artemis/artemis.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'note_graphql.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class NoteStatus$Query$Status with EquatableMixin {
  NoteStatus$Query$Status();

  factory NoteStatus$Query$Status.fromJson(Map<String, dynamic> json) =>
      _$NoteStatus$Query$StatusFromJson(json);

  String summary;

  @override
  List<Object> get props => [summary];
  Map<String, dynamic> toJson() => _$NoteStatus$Query$StatusToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NoteStatus$Query with EquatableMixin {
  NoteStatus$Query();

  factory NoteStatus$Query.fromJson(Map<String, dynamic> json) =>
      _$NoteStatus$QueryFromJson(json);

  NoteStatus$Query$Status status;

  @override
  List<Object> get props => [status];
  Map<String, dynamic> toJson() => _$NoteStatus$QueryToJson(this);
}

class NoteStatusQuery extends GraphQLQuery<NoteStatus$Query, JsonSerializable> {
  NoteStatusQuery();

  @override
  final DocumentNode document = DocumentNode(definitions: [
    OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: 'note_status'),
        variableDefinitions: [],
        directives: [],
        selectionSet: SelectionSetNode(selections: [
          FieldNode(
              name: NameNode(value: 'status'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: SelectionSetNode(selections: [
                FieldNode(
                    name: NameNode(value: 'summary'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null)
              ]))
        ]))
  ]);

  @override
  final String operationName = 'note_status';

  @override
  List<Object> get props => [document, operationName];
  @override
  NoteStatus$Query parse(Map<String, dynamic> json) =>
      NoteStatus$Query.fromJson(json);
}
