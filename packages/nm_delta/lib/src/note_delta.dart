// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'item_op.dart';
import 'sequence_delta.dart';
import 'string_delta.dart';

class NoteID extends ItemOp<String> {
  NoteID.put(String item) : super.put(item);
  NoteID.delete() : super.delete();
}

class NoteIDs extends SequenceDelta<String> {
  NoteIDs.insert(Iterable<String> ids) : super.insert(ids);
  NoteIDs.retain(int length) : super.retain(length);
  NoteIDs.delete(int length) : super.delete(length);
  NoteIDs.unmodifiable(Iterable<SequenceOp<String>> ops)
      : super.unmodifiable(ops);
}

class NoteValue extends StringDelta {
  NoteValue.insertString(String text) : super.insertString(text);
  NoteValue.retain(int length) : super.retain(length);
  NoteValue.delete(int length) : super.delete(length);
  NoteValue.unmodifiable(Iterable<SequenceOp<int>> ops)
      : super.unmodifiable(ops);
}

class NoteDelta {
  final StringDelta value;
  final ItemOp<String> valueTypeID;
  final SequenceDelta<String> contentIDs;
  final SequenceDelta<String> typeIDs;
  final bool _isBase;
  final bool _modifiable;

  NoteDelta({this.value, this.valueTypeID, this.contentIDs, this.typeIDs})
      : _isBase = null,
        _modifiable = true;

  NoteDelta.unmodifiable(
      {StringDelta value,
      this.valueTypeID,
      SequenceDelta<String> contentIDs,
      SequenceDelta<String> typeIDs})
      : value = value == null ? null : value.toUnmodifiable(),
        contentIDs = contentIDs == null ? null : contentIDs.toUnmodifiable(),
        typeIDs = typeIDs == null ? null : typeIDs.toUnmodifiable(),
        _isBase = (value == null || value.isBase) &&
            (valueTypeID == null || valueTypeID.isBase) &&
            (contentIDs == null || contentIDs.isBase) &&
            (typeIDs == null || typeIDs.isBase),
        _modifiable = false;

  bool get isBase => _modifiable
      ? (value == null || value.isBase) &&
          (valueTypeID == null || valueTypeID.isBase) &&
          (contentIDs == null || contentIDs.isBase) &&
          (typeIDs == null || typeIDs.isBase)
      : _isBase;

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (value != null) {
      json['v'] = value.toJson();
    }
    if (valueTypeID != null) {
      json['vt'] = valueTypeID.toJson();
    }
    if (contentIDs != null) {
      json['cs'] = contentIDs.toJson();
    }
    if (typeIDs != null) {
      json['ts'] = typeIDs.toJson();
    }
    return json;
  }

  NoteDelta toUnmodifiable() => _modifiable
      ? NoteDelta.unmodifiable(
          value: value,
          valueTypeID: valueTypeID,
          contentIDs: contentIDs,
          typeIDs: typeIDs)
      : this;

  NoteDelta apply(NoteDelta d) {
    return NoteDelta.unmodifiable(
        value: value == null
            ? d.value
            : d.value == null
                ? value
                : value.apply(d.value),
        valueTypeID: valueTypeID == null
            ? d.valueTypeID
            : d.valueTypeID == null
                ? valueTypeID
                : valueTypeID.apply(d.valueTypeID),
        contentIDs: contentIDs == null
            ? d.contentIDs
            : d.contentIDs == null
                ? contentIDs
                : contentIDs.apply(d.contentIDs),
        typeIDs: typeIDs == null
            ? d.typeIDs
            : d.typeIDs == null
                ? typeIDs
                : typeIDs.apply(d.typeIDs));
  }
}
