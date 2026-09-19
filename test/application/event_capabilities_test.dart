import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_capabilities.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/entities/event.dart';
import 'package:uman_event_manager/infrastructure/cloud/event_codec.dart';
import '../cloud_controller_test.dart' show sample;

void main() {
  test('online empty membership does not grant creation or Event access', () {
    const state = EventState(online: true);
    expect(state.capabilities().canCreate, false);
    expect(state.capabilities(sample().id).accessRevoked, true);
  });
  test(
    'offline and saving states disable mutations but preserve visible data',
    () {
      for (final state in [
        EventState(events: [sample()]),
        EventState(
          events: [sample()],
          online: true,
          saveStatus: SaveStatus.saving,
        ),
      ]) {
        expect(state.capabilities(sample().id).canEdit, false);
        expect(state.events, hasLength(1));
      }
    },
  );
  test('archival is final and restore only restores tombstones', () {
    final archived = decodeEvent({
      ...encodeEvent(sample()),
      'lifecycle_stage': 'ARCHIVED',
    });
    final deleted = decodeEvent({
      ...encodeEvent(archived),
      'is_deleted': true,
      'deleted_at_utc': '2026-09-19T00:00:00Z',
    });
    for (final event in [archived, deleted]) {
      final c = EventState(
        events: [event],
        online: true,
      ).capabilities(event.id);
      expect(c.canEdit, false);
      expect(c.canArchive, false);
      expect(c.canTransition, false);
      expect(c.canRestore, event.isDeleted);
    }
  });
  test('readiness is blocked; specified later transitions remain explicit', () {
    expect(
      EventState(
        events: [sample()],
        online: true,
      ).capabilities(sample().id).transitions,
      isEmpty,
    );
    final ready = decodeEvent({
      ...encodeEvent(sample()),
      'lifecycle_stage': 'READY',
    });
    expect(
      EventState(
        events: [ready],
        online: true,
      ).capabilities(ready.id).transitions,
      [EventLifecycleStage.planning, EventLifecycleStage.travel],
    );
  });
  test('unauthenticated state never enables creation', () {
    const c = EventCapabilities(
      authenticated: false,
      online: true,
      saving: false,
      hasMembership: true,
    );
    expect(c.canCreate, false);
  });
}
