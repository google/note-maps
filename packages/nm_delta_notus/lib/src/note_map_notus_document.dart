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

import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:nm_delta/nm_delta.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart' as quill;

import 'custom_attributes.dart';

/// NoteMapNotusDocument attempts to keep a NoteMapBuffer and a NotusDocument
/// in sync by transforming changes between the two.
///
/// If it encounters a change it doesn't know how to correctly transform, it
/// sends an error on the changes stream. When this happens, any dependent app
/// should just give up and apologize to the user.
class NoteMapNotusDocument {
  static final Uuid _uuid = Uuid();

  final String rootId;
  final NoteMapBuffer noteMap;
  final NotusDocument notusDocument;
  final StreamController<NoteMapChange> _changes;
  final String Function() _newId;

  NoteMapNotusDocument(this.rootId, {String Function() newId})
      : noteMap = NoteMapBuffer(),
        notusDocument = NotusDocument(),
        _changes = StreamController<NoteMapChange>(),
        _newId = newId ?? _uuid.v4 {
    notusDocument.changes.listen(_onNotusDocumentChange,
        onError: _onNotusDocumentError, onDone: _onNotusDocumentDone);
    noteMap.changes.listen(_onNoteMapBufferChange,
        onError: _onNoteMapBufferError, onDone: _onNoteMapBufferDone);
  }

  Stream<NoteMapChange> get changes => _changes.stream;

  void _onNotusDocumentChange(NotusChange notusChange) {
    if (notusChange.source == ChangeSource.local) {
      var noteMapDelta = NoteMapDelta();
      final changeIt = quill.DeltaIterator(notusChange.change);
      var changeIndex = 0;
      final base = _toSituatedNotes(notusChange.before);
      final baseIt = base.iterator;
      baseIt.moveNext();
      var baseNote = baseIt.current;
      final baseAdvance = () {
        while (baseNote != null &&
            baseNote.end < changeIndex &&
            baseIt.moveNext()) {
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
              final noteId = baseNote.noteId ?? _newId();
              noteMapDelta = noteMapDelta.apply(NoteMapDelta.from({
                noteId: NoteDelta(
                    value: NoteValue.retain(changeIndex - baseNote.start)
                      ..insertString(changeOp.data)),
              }));
              if (baseNote.isNew) {
                noteMapDelta = noteMapDelta.apply(NoteMapDelta.from({
                  rootId: NoteDelta(contentIDs: NoteIDs.insert([noteId])),
                }));
                notusDocument.format(baseNote.start, baseNote.end,
                    NoteMapNotusAttribute.lineId.withValue(noteId));
              }
            }
            break;
          case 'delete':
            break;
        }
      }
      noteMap.apply(noteMapDelta, NoteMapChangeSource.local);
    }
  }

  void _onNotusDocumentError(Object error) => _changes.addError(error);
  void _onNotusDocumentDone() => _changes.close();
  void _onNoteMapBufferChange(NoteMapChange change) => _changes.add(change);
  void _onNoteMapBufferError(Object error) => _changes.addError(error);
  void _onNoteMapBufferDone() => _changes.close();
}

class _SituatedNote {
  final int start;
  final int length;
  int get end => start + length;
  final String noteId; // null if this is a pending/new note.
  final String value;
  final bool editable; // false if this is a brief note identifier.
  bool get isNew => noteId == null;
  //final Delta delta; // just the ops that describe this note.
  _SituatedNote(
      {this.start, this.length, this.noteId, this.value, this.editable = true});
}

/// Assumes that all ops in quillDelta are 'insert' ops.
List<_SituatedNote> _toSituatedNotes(quill.Delta quillDelta) {
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
        start: istart, length: iend - istart, noteId: noteId, value: content));
  }
  return situated;
}
