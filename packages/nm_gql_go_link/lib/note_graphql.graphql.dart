// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:meta/meta.dart';
import 'package:artemis/artemis.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'note_graphql.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class NoteSimpleQuery$Query with EquatableMixin {
  NoteSimpleQuery$Query();

  factory NoteSimpleQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$NoteSimpleQuery$QueryFromJson(json);

  List<NoteSimpleQuery$Query$Todo> todos;

  @override
  List<Object> get props => [todos];
  Map<String, dynamic> toJson() => _$NoteSimpleQuery$QueryToJson(this);
}

class NoteSimpleQueryQuery
    extends GraphQLQuery<NoteSimpleQuery$Query, JsonSerializable> {
  NoteSimpleQueryQuery();

  @override
  final DocumentNode document = DocumentNode(definitions: [
    OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: 'note_simple_query'),
        variableDefinitions: [],
        directives: [],
        selectionSet: SelectionSetNode(selections: [
          FieldNode(
              name: NameNode(value: 'todos'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null)
        ]))
  ]);

  @override
  final String operationName = 'note_simple_query';

  @override
  List<Object> get props => [document, operationName];
  @override
  NoteSimpleQuery$Query parse(Map<String, dynamic> json) =>
      NoteSimpleQuery$Query.fromJson(json);
}
