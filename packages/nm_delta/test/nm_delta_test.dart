import 'package:nm_delta/nm_delta.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    NoteMapDeltaBuilder noteMap;

    setUp(() {
      noteMap = NoteMapDeltaBuilder();
    });

    test('First Test', () {
      expect(true, isTrue);
    });
  });
}
