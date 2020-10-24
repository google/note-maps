import 'package:nm_delta/nm_delta.dart';
import 'package:nm_delta_notus/nm_delta_notus.dart';
//import 'package:nm_delta_storage/nm_delta_storage.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('QuillDocumentCodec', () {
    test('one simple content note', () {
      final quillDocument = Delta()
        ..insert('abcdef')
        ..insert('\n', {'nm_line_id': 'note0'});
      final noteMap = NoteMapDelta.from({
        '': NoteDelta(contentIDs: NoteIDs.insert(['note0'])),
        'note0': NoteDelta(value: NoteValue.insertString('abcdef')),
      });
      expect(quillDocumentCodec.decoder.convert(quillDocument).toJson(),
          noteMap.toJson());
      expect(
          quillDocumentCodec.encoder
              .convert(noteMap)
              .toList()
              .map((d) => d.toJson())
              .toList(),
          quillDocument.toList().map((d) => d.toJson()).toList());
    });
  });
}
