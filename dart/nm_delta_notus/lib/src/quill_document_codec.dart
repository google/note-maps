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

import 'dart:convert';

import 'package:quill_delta/quill_delta.dart';
import 'package:nm_delta/nm_delta.dart';

import 'custom_attributes.dart';

class QuillDocumentCodec extends Codec<NoteMapDelta, Delta> {
  const QuillDocumentCodec();

  @override
  Converter<NoteMapDelta, Delta> get encoder =>
      _NoteMapToQuillDocumentConverter();

  @override
  Converter<Delta, NoteMapDelta> get decoder =>
      _QuillDocumentToNoteMapConverter();
}

const QuillDocumentCodec quillDocumentCodec = QuillDocumentCodec();

class _QuillDocumentToNoteMapConverter extends Converter<Delta, NoteMapDelta> {
  @override
  NoteMapDelta convert(Delta input) {
    final values = <String, String>{};
    final contentIDs = <String, List<String>>{};
    final rootID = '';
    final iterator = DeltaIterator(input);
    var text = '';
    while (iterator.hasNext) {
      final op = iterator.next();
      if (!op.isInsert) {
        throw ArgumentError('insert-only delta required');
      }
      final op_text = op.data.toString();
      if (op_text.endsWith('\n')) {
        text += op_text.substring(0, op_text.length - 1);
      } else {
        text += op_text;
      }
      final line_id = op.attributes == null
          ? null
          : op.attributes[NoteMapNotusAttribute.lineId.key];
      if (line_id != null) {
        final id = op.attributes[NoteMapNotusAttribute.lineId.key] ?? '';
        if (id != '') {
          contentIDs.putIfAbsent(rootID, () => []).add(id);
        }
        values[id] = text;
        text = '';
      }
    }
    final noteMapDeltas = [
      Map<String, NoteDelta>.fromEntries(contentIDs.entries.map((entry) =>
          MapEntry<String, NoteDelta>(
              entry.key, NoteDelta(contentIDs: NoteIDs.insert(entry.value))))),
      Map<String, NoteDelta>.fromEntries(values.entries.map((entry) {
        final delta = NoteDelta(value: NoteValue.insertString(entry.value));
        return MapEntry<String, NoteDelta>(entry.key, delta);
      })),
    ].map((m) => NoteMapDelta.from(m));
    return noteMapDeltas.fold(NoteMapDelta(), (prev, d) => prev.apply(d));
  }
}

class _NoteMapToQuillDocumentConverter extends Converter<NoteMapDelta, Delta> {
  @override
  Delta convert(NoteMapDelta noteMap) {
    final delta = Delta();
    final root = noteMap[''];
    for (var id in root.contentIDs?.toBaseIterable() ?? []) {
      final note_delta = noteMap[id];
      delta.insert(note_delta.value.toBaseString());
      delta.insert('\n', {NoteMapNotusAttribute.lineId.key: id});
    }
    return delta;
  }
}
