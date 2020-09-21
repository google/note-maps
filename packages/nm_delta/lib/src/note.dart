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

import 'list.dart';
import 'single.dart';

// Describes a single note in isolation from other notes.
//
// Useful for fully representing the state of a single note in a note map.
class Note {
  // Value of this note.
  final String valueString;

  // ID of a note that describes the data type of the string stored in
  // ValueString.
  final String valueTypeID;

  // IDs of notes that are children of this note.
  final List<String> contentIDs;

  // IDs of notes that represent types, categories, or tags that apply to
  // this note.
  final List<String> typeIDs;

  Note({this.valueString, this.valueTypeID, this.contentIDs, this.typeIDs});
}

class NoteDelta {
  final ListDelta<int> valueString;
  final SingleOperation<String> valueTypeID;
  final ListDelta<String> contentIDs;
  final ListDelta<String> typeIDs;
  NoteDelta(
      {this.valueString, this.valueTypeID, this.contentIDs, this.typeIDs});
  Note toNote() {
    return Note(
        valueString: String.fromCharCodes(valueString.flatten()),
        valueTypeID: valueTypeID.flatten(),
        contentIDs: contentIDs.flatten(),
        typeIDs: typeIDs.flatten());
  }
}

class NoteDeltaBuilder {
  final ListDeltaBuilder<int> valueString;
  final SingleOperationBuilder<String> valueTypeID;
  final ListDeltaBuilder<String> contentIDs;
  final ListDeltaBuilder<String> typeIDs;
  NoteDeltaBuilder()
      : valueString = ListDeltaBuilder<int>(),
        valueTypeID = SingleOperationBuilder<String>(),
        contentIDs = ListDeltaBuilder<String>(),
        typeIDs = ListDeltaBuilder<String>();
  NoteDelta delta() {
    return NoteDelta(
        valueString: valueString.delta(),
        valueTypeID: valueTypeID.operation(),
        contentIDs: contentIDs.delta(),
        typeIDs: typeIDs.delta());
  }
}
