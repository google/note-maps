///
//  Generated code. Do not modify.
//  source: pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const Mask$json = const {
  '1': 'Mask',
  '2': const [
    const {'1': 'UnspecifiedMask', '2': 0},
    const {'1': 'IdsMask', '2': 1},
    const {'1': 'RefsMask', '2': 2},
    const {'1': 'TopicsMask', '2': 3},
    const {'1': 'NamesMask', '2': 4},
    const {'1': 'OccurrencesMask', '2': 5},
    const {'1': 'ValueMask', '2': 6},
    const {'1': 'ParentMask', '2': 7},
  ],
};

const RefType$json = const {
  '1': 'RefType',
  '2': const [
    const {'1': 'UnspecifiedRefType', '2': 0},
    const {'1': 'ItemIdentifier', '2': 1},
    const {'1': 'SubjectIdentifier', '2': 2},
    const {'1': 'SubjectLocator', '2': 3},
  ],
};

const ItemType$json = const {
  '1': 'ItemType',
  '2': const [
    const {'1': 'UnspecifiedItem', '2': 0},
    const {'1': 'LibraryItem', '2': 1},
    const {'1': 'TopicMapItem', '2': 2},
    const {'1': 'TopicItem', '2': 3},
    const {'1': 'NameItem', '2': 4},
    const {'1': 'OccurrenceItem', '2': 6},
  ],
};

const Orderable$json = const {
  '1': 'Orderable',
  '2': const [
    const {'1': 'OrderableUnspecified', '2': 0},
    const {'1': 'OrderableNames', '2': 1},
    const {'1': 'OrderableOccurrences', '2': 2},
  ],
};

const Library$json = const {
  '1': 'Library',
  '2': const [
    const {'1': 'topic_map_ids', '3': 1, '4': 3, '5': 4, '10': 'topicMapIds'},
  ],
};

const TopicMap$json = const {
  '1': 'TopicMap',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'topic', '3': 2, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Topic', '10': 'topic'},
    const {'1': 'in_trash', '3': 3, '4': 1, '5': 8, '10': 'inTrash'},
  ],
};

const Topic$json = const {
  '1': 'Topic',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'names', '3': 3, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.Name', '10': 'names'},
    const {'1': 'occurrences', '3': 4, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.Occurrence', '10': 'occurrences'},
    const {'1': 'name_ids', '3': 5, '4': 3, '5': 4, '10': 'nameIds'},
    const {'1': 'occurrence_ids', '3': 6, '4': 3, '5': 4, '10': 'occurrenceIds'},
  ],
};

const Name$json = const {
  '1': 'Name',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'parent_id', '3': 2, '4': 1, '5': 4, '10': 'parentId'},
    const {'1': 'id', '3': 3, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'value', '3': 4, '4': 1, '5': 9, '10': 'value'},
  ],
};

const Occurrence$json = const {
  '1': 'Occurrence',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'parent_id', '3': 2, '4': 1, '5': 4, '10': 'parentId'},
    const {'1': 'id', '3': 3, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'value', '3': 4, '4': 1, '5': 9, '10': 'value'},
  ],
};

const TupleSequence$json = const {
  '1': 'TupleSequence',
  '2': const [
    const {'1': 'tuples', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.Tuple', '10': 'tuples'},
  ],
};

const Tuple$json = const {
  '1': 'Tuple',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.AnyItem', '10': 'items'},
  ],
};

const AnyItem$json = const {
  '1': 'AnyItem',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'item_id', '3': 2, '4': 1, '5': 4, '10': 'itemId'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
    const {'1': 'refs', '3': 4, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.Ref', '10': 'refs'},
    const {'1': 'name_ids', '3': 5, '4': 3, '5': 4, '10': 'nameIds'},
    const {'1': 'names', '3': 6, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.AnyItem', '10': 'names'},
    const {'1': 'occurrence_ids', '3': 7, '4': 3, '5': 4, '10': 'occurrenceIds'},
    const {'1': 'occurrences', '3': 8, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.AnyItem', '10': 'occurrences'},
    const {'1': 'value', '3': 9, '4': 1, '5': 9, '10': 'value'},
    const {'1': 'type_ref', '3': 10, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Ref', '10': 'typeRef'},
    const {'1': 'role_ids', '3': 12, '4': 3, '5': 4, '10': 'roleIds'},
    const {'1': 'roles', '3': 13, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.AnyItem', '10': 'roles'},
    const {'1': 'player_ref', '3': 11, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Ref', '10': 'playerRef'},
  ],
};

const Ref$json = const {
  '1': 'Ref',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.RefType', '10': 'type'},
    const {'1': 'iri', '3': 2, '4': 1, '5': 9, '10': 'iri'},
  ],
};

const Item$json = const {
  '1': 'Item',
  '2': const [
    const {'1': 'library', '3': 1, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Library', '9': 0, '10': 'library'},
    const {'1': 'topic_map', '3': 2, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.TopicMap', '9': 0, '10': 'topicMap'},
    const {'1': 'topic', '3': 3, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Topic', '9': 0, '10': 'topic'},
    const {'1': 'name', '3': 4, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Name', '9': 0, '10': 'name'},
    const {'1': 'occurrence', '3': 6, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Occurrence', '9': 0, '10': 'occurrence'},
  ],
  '8': const [
    const {'1': 'specific'},
  ],
};

const LoadRequest$json = const {
  '1': 'LoadRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
  ],
};

const LoadResponse$json = const {
  '1': 'LoadResponse',
  '2': const [
    const {'1': 'item', '3': 1, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Item', '10': 'item'},
  ],
};

const SearchRequest$json = const {
  '1': 'SearchRequest',
  '2': const [
    const {'1': 'topic_map_ids', '3': 1, '4': 3, '5': 4, '10': 'topicMapIds'},
    const {'1': 'tmql', '3': 2, '4': 1, '5': 9, '10': 'tmql'},
  ],
};

const SearchResponse$json = const {
  '1': 'SearchResponse',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.Item', '10': 'items'},
    const {'1': 'count', '3': 2, '4': 1, '5': 4, '10': 'count'},
    const {'1': 'offset', '3': 3, '4': 1, '5': 4, '10': 'offset'},
  ],
};

const QueryRequest$json = const {
  '1': 'QueryRequest',
  '2': const [
    const {'1': 'load_requests', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.LoadRequest', '10': 'loadRequests'},
    const {'1': 'search_requests', '3': 2, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.SearchRequest', '10': 'searchRequests'},
  ],
};

const QueryResponse$json = const {
  '1': 'QueryResponse',
  '2': const [
    const {'1': 'load_responses', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.LoadResponse', '10': 'loadResponses'},
    const {'1': 'search_responses', '3': 2, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.SearchResponse', '10': 'searchResponses'},
  ],
};

const CreationRequest$json = const {
  '1': 'CreationRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'parent', '3': 2, '4': 1, '5': 4, '10': 'parent'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
  ],
};

const UpdateOrderRequest$json = const {
  '1': 'UpdateOrderRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'orderable', '3': 4, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.Orderable', '10': 'orderable'},
    const {'1': 'src_indices', '3': 5, '4': 3, '5': 13, '10': 'srcIndices'},
    const {'1': 'dst_indices', '3': 6, '4': 3, '5': 13, '10': 'dstIndices'},
  ],
};

const UpdateValueRequest$json = const {
  '1': 'UpdateValueRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
    const {'1': 'value', '3': 4, '4': 1, '5': 9, '10': 'value'},
  ],
};

const UpdateResponse$json = const {
  '1': 'UpdateResponse',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item', '3': 3, '4': 1, '5': 11, '6': '.notemaps.tmaps.pb.Item', '10': 'item'},
  ],
};

const DeletionRequest$json = const {
  '1': 'DeletionRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
  ],
};

const DeletionResponse$json = const {
  '1': 'DeletionResponse',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.notemaps.tmaps.pb.ItemType', '10': 'itemType'},
  ],
};

const MutationRequest$json = const {
  '1': 'MutationRequest',
  '2': const [
    const {'1': 'creation_requests', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.CreationRequest', '10': 'creationRequests'},
    const {'1': 'update_order_requests', '3': 2, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.UpdateOrderRequest', '10': 'updateOrderRequests'},
    const {'1': 'update_value_requests', '3': 3, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.UpdateValueRequest', '10': 'updateValueRequests'},
    const {'1': 'deletion_requests', '3': 4, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.DeletionRequest', '10': 'deletionRequests'},
  ],
};

const MutationResponse$json = const {
  '1': 'MutationResponse',
  '2': const [
    const {'1': 'creation_responses', '3': 1, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.UpdateResponse', '10': 'creationResponses'},
    const {'1': 'update_order_responses', '3': 2, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.UpdateResponse', '10': 'updateOrderResponses'},
    const {'1': 'update_value_responses', '3': 3, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.UpdateResponse', '10': 'updateValueResponses'},
    const {'1': 'deletion_responses', '3': 4, '4': 3, '5': 11, '6': '.notemaps.tmaps.pb.DeletionResponse', '10': 'deletionResponses'},
  ],
};

