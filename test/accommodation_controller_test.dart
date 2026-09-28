import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/accommodation_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/accommodation_fakes.dart';

void main() {
  late EventController events;
  late FakeRepository eventRepo;
  late FakeAccommodationRepository repo;
  late AccommodationController controller;
  setUp(() async {
    eventRepo = FakeRepository();
    events = EventController(eventRepo, MemoryCache());
    await events.start();
    repo = FakeAccommodationRepository();
    controller = AccommodationController(
      repo,
      events,
      pollInterval: const Duration(milliseconds: 40),
    );
    await controller.start();
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  test(
    'Realtime invalidation and reconnect refresh canonical hierarchy',
    () async {
      repo.data = accSnapshot(version: 2);
      repo.changes.add(RepositorySignal.changed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.data.apartments.single.version, 2);
      repo.changes.add(RepositorySignal.disconnected);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.realtimeConnected, false);
      repo.data = accSnapshot(version: 3);
      repo.changes.add(RepositorySignal.connected);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.realtimeConnected, true);
      expect(controller.state.data.apartments.single.version, 3);
    },
  );
  test('Bounded reconciliation repairs missed notification', () async {
    repo.data = accSnapshot(version: 2);
    await Future<void>.delayed(const Duration(milliseconds: 65));
    expect(controller.state.data.apartments.single.version, 2);
  });
  test(
    'Invalidation during read serializes and reruns without losing notification',
    () async {
      final gate = Completer<void>();
      repo.gate = gate;
      final pending = controller.refresh();
      final reads = repo.reads;
      repo.changes.add(RepositorySignal.changed);
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await pending;
      expect(repo.reads, greaterThan(reads));
      expect(repo.maxActiveReads, 1);
    },
  );
  test(
    'Close disposes subscriptions, timer and repository during a read',
    () async {
      final gate = Completer<void>();
      repo.gate = gate;
      final pending = controller.refresh();
      await controller.close();
      final reads = repo.reads;
      gate.complete();
      await pending;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repo.reads, reads);
      expect(repo.disposed, true);
      expect(repo.changes.hasListener, false);
    },
  );
  test(
    'Read authorization failure clears all hierarchy and stops subscription',
    () async {
      repo.readFailure = CloudFailureKind.unauthorized;
      await controller.refresh();
      expect(controller.state.data.apartments, isEmpty);
      expect(controller.state.data.people, isEmpty);
      expect(controller.state.canWrite, false);
      expect(repo.changes.hasListener, false);
    },
  );
  test(
    'Event access revocation cannot be repopulated by in-flight data',
    () async {
      final gate = Completer<void>();
      repo.gate = gate;
      final pending = controller.refresh();
      eventRepo.rows = [];
      await events.reconcile();
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await pending;
      expect(controller.state.data.apartments, isEmpty);
      expect(controller.state.canWrite, false);
    },
  );
  test(
    'Concurrent submit prevented; success only follows committed response',
    () async {
      repo.writeGate = Completer<void>();
      final pending = controller.save(apartmentInput, requestId: aptId);
      expect(controller.state.save, SaveStatus.saving);
      expect(await controller.save(apartmentInput, requestId: aptId), false);
      repo.writeGate!.complete();
      expect(await pending, true);
      expect(repo.writes, 1);
    },
  );
  test('CAS conflict persists through reconciliation', () async {
    repo.writeFailure = CloudFailureKind.conflict;
    expect(
      await controller.save(
        apartmentInput,
        requestId: aptId,
        base: repo.data.apartments.single,
      ),
      false,
    );
    await controller.refresh();
    expect(controller.state.save, SaveStatus.conflict);
    expect(controller.state.failure, CloudFailureKind.conflict);
  });
  test('Delete and restore reload canonical tombstone state', () async {
    await controller.setDeleted(repo.data.apartments.single, true);
    expect(controller.state.data.apartments.single.isDeleted, true);
    await controller.setDeleted(repo.data.apartments.single, false);
    expect(controller.state.data.apartments.single.isDeleted, false);
  });
  test('Offline failure preserves stale read but prevents writes', () async {
    repo.readFailure = CloudFailureKind.unavailable;
    await controller.refresh();
    expect(controller.state.data.apartments, isNotEmpty);
    expect(controller.state.canWrite, false);
  });
}
