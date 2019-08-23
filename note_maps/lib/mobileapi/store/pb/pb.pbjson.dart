///
//  Generated code. Do not modify.
//  source: store/pb/pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

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
    const {'1': 'topic', '3': 2, '4': 1, '5': 11, '6': '.Topic', '10': 'topic'},
    const {'1': 'in_trash', '3': 3, '4': 1, '5': 8, '10': 'inTrash'},
  ],
};

const Topic$json = const {
  '1': 'Topic',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'names', '3': 3, '4': 3, '5': 11, '6': '.Name', '10': 'names'},
    const {'1': 'occurrences', '3': 4, '4': 3, '5': 11, '6': '.Occurrence', '10': 'occurrences'},
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

const Item$json = const {
  '1': 'Item',
  '2': const [
    const {'1': 'library', '3': 1, '4': 1, '5': 11, '6': '.Library', '9': 0, '10': 'library'},
    const {'1': 'topic_map', '3': 2, '4': 1, '5': 11, '6': '.TopicMap', '9': 0, '10': 'topicMap'},
    const {'1': 'topic', '3': 3, '4': 1, '5': 11, '6': '.Topic', '9': 0, '10': 'topic'},
    const {'1': 'name', '3': 4, '4': 1, '5': 11, '6': '.Name', '9': 0, '10': 'name'},
    const {'1': 'occurrence', '3': 6, '4': 1, '5': 11, '6': '.Occurrence', '9': 0, '10': 'occurrence'},
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
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.ItemType', '10': 'itemType'},
  ],
};

const LoadResponse$json = const {
  '1': 'LoadResponse',
  '2': const [
    const {'1': 'item', '3': 1, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
  ],
};

const QueryRequest$json = const {
  '1': 'QueryRequest',
  '2': const [
    const {'1': 'load_requests', '3': 1, '4': 3, '5': 11, '6': '.LoadRequest', '10': 'loadRequests'},
  ],
};

const QueryResponse$json = const {
  '1': 'QueryResponse',
  '2': const [
    const {'1': 'load_responses', '3': 1, '4': 3, '5': 11, '6': '.LoadResponse', '10': 'loadResponses'},
  ],
};

const CreationRequest$json = const {
  '1': 'CreationRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'parent', '3': 2, '4': 1, '5': 4, '10': 'parent'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.ItemType', '10': 'itemType'},
  ],
};

const UpdateOrderRequest$json = const {
  '1': 'UpdateOrderRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'orderable', '3': 4, '4': 1, '5': 14, '6': '.Orderable', '10': 'orderable'},
    const {'1': 'src_indices', '3': 5, '4': 3, '5': 13, '10': 'srcIndices'},
    const {'1': 'dst_indices', '3': 6, '4': 3, '5': 13, '10': 'dstIndices'},
  ],
};

const UpdateValueRequest$json = const {
  '1': 'UpdateValueRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.ItemType', '10': 'itemType'},
    const {'1': 'value', '3': 4, '4': 1, '5': 9, '10': 'value'},
  ],
};

const UpdateResponse$json = const {
  '1': 'UpdateResponse',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item', '3': 3, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
  ],
};

const DeletionRequest$json = const {
  '1': 'DeletionRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.ItemType', '10': 'itemType'},
  ],
};

const DeletionResponse$json = const {
  '1': 'DeletionResponse',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'item_type', '3': 3, '4': 1, '5': 14, '6': '.ItemType', '10': 'itemType'},
  ],
};

const MutationRequest$json = const {
  '1': 'MutationRequest',
  '2': const [
    const {'1': 'creation_requests', '3': 1, '4': 3, '5': 11, '6': '.CreationRequest', '10': 'creationRequests'},
    const {'1': 'update_order_requests', '3': 2, '4': 3, '5': 11, '6': '.UpdateOrderRequest', '10': 'updateOrderRequests'},
    const {'1': 'update_value_requests', '3': 3, '4': 3, '5': 11, '6': '.UpdateValueRequest', '10': 'updateValueRequests'},
    const {'1': 'deletion_requests', '3': 4, '4': 3, '5': 11, '6': '.DeletionRequest', '10': 'deletionRequests'},
  ],
};

const MutationResponse$json = const {
  '1': 'MutationResponse',
  '2': const [
    const {'1': 'creation_responses', '3': 1, '4': 3, '5': 11, '6': '.UpdateResponse', '10': 'creationResponses'},
    const {'1': 'update_order_responses', '3': 2, '4': 3, '5': 11, '6': '.UpdateResponse', '10': 'updateOrderResponses'},
    const {'1': 'update_value_responses', '3': 3, '4': 3, '5': 11, '6': '.UpdateResponse', '10': 'updateValueResponses'},
    const {'1': 'deletion_responses', '3': 4, '4': 3, '5': 11, '6': '.DeletionResponse', '10': 'deletionResponses'},
  ],
};

