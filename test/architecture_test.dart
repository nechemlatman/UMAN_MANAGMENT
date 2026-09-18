import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Domain and application do not import backend or platform libraries', () {
    for (final layer in ['domain', 'application']) {
      for (final f
          in Directory('lib/$layer')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        for (final line in f.readAsLinesSync().where(
          (l) => l.startsWith('import '),
        )) {
          expect(
            line,
            isNot(
              matches(
                r'package:(flutter|supabase|drift|sqlite3)|dart:(io|ffi|ui)|infrastructure/',
              ),
            ),
            reason: f.path,
          );
        }
      }
    }
  });
  test('Presentation has no backend SDK or database dependency', () {
    for (final f
        in Directory('lib/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      expect(f.readAsStringSync(), isNot(contains('supabase_flutter')));
      expect(f.readAsStringSync(), isNot(contains('NativeDatabase')));
    }
  });
}
