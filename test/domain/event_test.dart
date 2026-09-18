import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/event.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';
import 'package:uman_event_manager/domain/value_objects/uuid_v4.dart';
import '../support/fixtures.dart';

void main() {
  test('UUIDs have v4 version/variant and distinct random identity', () {
    final ids = List.generate(500, (_) => UuidV4.generate());
    expect(ids.every(UuidV4.isValid), isTrue);
    expect(ids.toSet().length, 500);
    expect(UuidV4.isValid('11111111-1111-1111-1111-111111111111'), isFalse);
  });
  test('CivilDate validates real calendar dates without timezone shifts', () {
    expect(CivilDate.parse('2024-02-29'), CivilDate(2024, 2, 29));
    expect(() => CivilDate(2025, 2, 29), throwsArgumentError);
    expect(
      () => CivilDate.parse('2026-09-09T00:00:00Z'),
      throwsFormatException,
    );
    expect(CivilDate(2026, 9, 9).toString(), '2026-09-09');
  });
  test(
    'Event equality preserves all fields, bilingual text and immutable JSON',
    () {
      final event = sampleEvent();
      expect(event, sampleEvent());
      expect(event, isNot(sampleEvent(name: 'Changed')));
      expect(event.hebrewName, 'אומן תשפ״ז');
      expect(() => event.settings['new'] = true, throwsUnsupportedError);
      final nested = event.settings['nested'] as Map;
      expect(() => (nested['values'] as List).add(3), throwsUnsupportedError);
    },
  );
  test('All lifecycle values round trip explicitly', () {
    for (final stage in EventLifecycleStage.values) {
      expect(EventLifecycleStage.fromStorageValue(stage.storageValue), stage);
    }
  });
  test('UTC and tombstone invariants reject invalid metadata', () {
    Event build(DateTime created, {bool deleted = false}) => Event(
      id: UuidV4.generate(),
      name: 'Event',
      year: 2026,
      startDate: CivilDate(2026, 9, 1),
      endDate: CivilDate(2026, 9, 2),
      baseCurrency: 'USD',
      lifecycleStage: EventLifecycleStage.planning,
      createdAtUtc: created,
      updatedAtUtc: DateTime.utc(2026),
      isDeleted: deleted,
    );
    expect(() => build(DateTime(2026)), throwsArgumentError);
    expect(() => build(DateTime.utc(2026), deleted: true), throwsArgumentError);
  });
}
