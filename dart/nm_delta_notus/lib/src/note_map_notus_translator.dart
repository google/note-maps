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

import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:nm_delta/nm_delta.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart' as quill;

import 'custom_attributes.dart';

/// Describes a delta to a note map and to a Notus document.
class NoteMapNotusDelta {
  final NoteMapDelta noteMap;
  final quill.Delta notus;
  NoteMapNotusDelta({this.noteMap, this.notus});
  bool get hasNoteMap => noteMap != null;
  bool get hasNotus => notus != null && notus.isNotEmpty;
  bool get isNotEmpty => hasNoteMap || hasNotus;
}

/// NoteMapNotusTranslator attempts to keep a NoteMapBuffer and a NotusDocument
/// in sync by transforming changes between the two.
///
/// If it encounters a change it doesn't know how to correctly transform, it
/// sends an error on the changes stream. When this happens, any dependent app
/// should just give up and apologize to the user.
class NoteMapNotusTranslator {
  static final Uuid _uuid = Uuid();

  final String rootId;
  final String Function() newId;

  NoteMapNotusTranslator(this.rootId, {String Function() newId})
      : newId = newId ?? _uuid.v4;

  /// Translates [notusChange] into the corresponding [NoteMapDelta].
  ///
  /// Returns a [NoteMapNotusChange] because the same change may require an
  /// additional delta to the corresponding [NotusDocument].
  NoteMapNotusDelta onNotusChange(NotusChange notusChange) {
    final logger = Logger();
    var noteMapResult = NoteMapDelta();
    var notusResult = quill.Delta();
    final changeIt = quill.DeltaIterator(notusChange.change);
    var changeIndex = 0;
    final base = _toSituatedNotes(notusChange.before, newId);
    final baseIt = base.iterator;
    baseIt.moveNext();
    var baseNote = baseIt.current;
    final baseAdvance = () {
      while (
          baseNote != null && baseNote.end < changeIndex && baseIt.moveNext()) {
        baseNote = baseIt.current;
      }
      return baseNote.start <= changeIndex;
    };
    while (changeIt.hasNext) {
      final changeOp = changeIt.next();
      switch (changeOp.key) {
        case 'retain':
          changeIndex += changeOp.length;
          break;
        case 'insert':
          if (baseAdvance()) {
            // baseNote now refers to a note whose representation in the
            // document overlaps the location of this insert operation.
            final noteId = baseNote.noteId;
            noteMapResult = noteMapResult.apply(NoteMapDelta.from({
              noteId: NoteDelta(
                  value: NoteValue.retain(changeIndex - baseNote.start)
                    ..insertString(changeOp.data)),
            }));
            baseNote.notusLengthDelta += changeOp.length;
            if (baseNote.isNew) {
              noteMapResult = noteMapResult.apply(NoteMapDelta.from({
                rootId: NoteDelta(contentIDs: NoteIDs.insert([noteId])),
              }));
            }
          }
          break;
        case 'delete':
          if (baseAdvance()) {
            baseNote.notusLengthDelta -= changeOp.length;
            logger.d('delete is not yet supported');
            /*
            final noteId = baseNote.noteId ?? newId();
            baseNote.noteMapDelta= NoteMapDelta.from({
              noteId: NoteDelta(
                  value: NoteValue.retain(changeIndex - baseNote.start)
                    ..insertString(changeOp.data)),
            }));
            baseNote.notusLengthDelta+=changeOp.data.length;
            if (baseNote.isNew) {
              noteMapResult = noteMapResult.apply(NoteMapDelta.from({
                rootId: NoteDelta(contentIDs: NoteIDs.insert([noteId])),
              }));
              baseNote.notusLineAttributes[ NoteMapNotusAttribute.lineId.key]= noteId;
            }
            */
          }
          break;
      }
    }
    for (var baseNote in base) {
      if (baseNote.notusLineAttributes.isNotEmpty) {
        notusResult = notusResult.compose(quill.Delta()
          ..retain(baseNote.end + baseNote.notusLengthDelta)
          ..retain(1, baseNote.notusLineAttributes));
      }
    }
    return NoteMapNotusDelta(noteMap: noteMapResult, notus: notusResult);
  }

  /// Translates a [NoteMapChange] against into a new [quill.Delta] describing
  /// that change against [base].
  ///
  /// Returns a [NoteMapNotusDelta] in case a corresponding change to the note
  /// map is also required.
  NoteMapNotusDelta onNoteMapChange(
      NoteMapChange noteMapChange, quill.Delta base) {
    throw UnimplementedError("whoops, that's not supported yet!");
  }
}

class _SituatedNote {
  final int start;
  final int length;
  int get end => start + length;
  final String noteId; // null if this is a pending/new note.
  final String value;
  final bool editable; // false if this is a brief note identifier.
  final bool isNew;
  int notusLengthDelta = 0;
  final Map<String, dynamic> notusLineAttributes;
  _SituatedNote(
      {this.start,
      this.length,
      this.noteId,
      this.isNew,
      this.value,
      this.editable = true})
      : notusLineAttributes = {} {
    if (isNew) {
      notusLineAttributes[NoteMapNotusAttribute.lineId.key] = noteId;
    }
  }
  dynamic toJson() => <String, dynamic>{
        'start': start,
        'length': length,
        'end': end,
        'noteId': noteId,
        'value': value,
        'editable': editable,
        'isNew': isNew
      };
}

/// Assumes that all ops in quillDelta are 'insert' ops.
List<_SituatedNote> _toSituatedNotes(
    quill.Delta quillDelta, String Function() newId) {
  final situated = <_SituatedNote>[];
  final it = quill.DeltaIterator(quillDelta);
  var i = 0; // character index into quillDelta
  quill.Operation op;
  while (it.hasNext || op != null) {
    var content = '';
    final istart = i;
    var iend = i;
    String noteId;
    while (it.hasNext || op != null) {
      op = op ?? it.next();
      noteId = op.attributes == null
          ? null
          : op.attributes[NoteMapNotusAttribute.lineId.key];
      if (!(op.data is String)) {
        throw UnimplementedError();
      } else if (op.data is String && op.data.contains('\n')) {
        final ni = op.data.indexOf('\n');
        content += op.data.substring(0, ni);
        op = ni + 1 == op.data.length
            ? null
            : quill.Operation.insert(op.data.substring(ni + 1), op.attributes);
        i += ni + 1;
        break;
      } else {
        content += op.data;
        i += op.length;
        op = null;
      }
      if (noteId != null) {
        break;
      }
    }
    situated.add(_SituatedNote(
        start: istart,
        length: iend - istart,
        noteId: noteId ?? newId(),
        value: content,
        isNew: noteId == null));
  }
  return situated;
}
