///
//  Generated code. Do not modify.
//  source: store/pb/pb.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const TopicMap$json = const {
  '1': 'TopicMap',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'topic', '3': 2, '4': 1, '5': 11, '6': '.Topic', '10': 'topic'},
  ],
};

const Topic$json = const {
  '1': 'Topic',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'topic_map_id', '3': 2, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'names', '3': 3, '4': 3, '5': 11, '6': '.Name', '10': 'names'},
    const {'1': 'occurrences', '3': 4, '4': 3, '5': 11, '6': '.Occurrence', '10': 'occurrences'},
  ],
};

const Name$json = const {
  '1': 'Name',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'parent_id', '3': 2, '4': 1, '5': 4, '10': 'parentId'},
    const {'1': 'value', '3': 3, '4': 1, '5': 9, '10': 'value'},
  ],
};

const Occurrence$json = const {
  '1': 'Occurrence',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    const {'1': 'parent_id', '3': 2, '4': 1, '5': 4, '10': 'parentId'},
    const {'1': 'value', '3': 3, '4': 1, '5': 9, '10': 'value'},
  ],
};

const GetTopicMapsRequest$json = const {
  '1': 'GetTopicMapsRequest',
  '2': const [
    const {'1': 'in_trash', '3': 1, '4': 1, '5': 8, '10': 'inTrash'},
  ],
};

const GetTopicMapsResponse$json = const {
  '1': 'GetTopicMapsResponse',
  '2': const [
    const {'1': 'topic_maps', '3': 1, '4': 3, '5': 11, '6': '.TopicMap', '10': 'topicMaps'},
  ],
};

const CreateTopicMapRequest$json = const {
  '1': 'CreateTopicMapRequest',
};

const CreateTopicMapResponse$json = const {
  '1': 'CreateTopicMapResponse',
  '2': const [
    const {'1': 'topic_map', '3': 1, '4': 1, '5': 11, '6': '.TopicMap', '10': 'topicMap'},
  ],
};

const DeleteTopicMapRequest$json = const {
  '1': 'DeleteTopicMapRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
    const {'1': 'fully_delete', '3': 2, '4': 1, '5': 8, '10': 'fullyDelete'},
  ],
};

const DeleteTopicMapResponse$json = const {
  '1': 'DeleteTopicMapResponse',
};

const RestoreTopicMapRequest$json = const {
  '1': 'RestoreTopicMapRequest',
  '2': const [
    const {'1': 'topic_map_id', '3': 1, '4': 1, '5': 4, '10': 'topicMapId'},
  ],
};

const RestoreTopicMapResponse$json = const {
  '1': 'RestoreTopicMapResponse',
};

