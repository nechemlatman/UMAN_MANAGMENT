import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/entities/event.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/infrastructure/cloud/event_codec.dart';

Event sample([int version = 1, String name = 'Uman']) => decodeEvent({
  'id': '11111111-1111-4111-8111-111111111111',
  'name': name,
  'year': 2026,
  'start_date': '2026-09-01',
  'end_date': '2026-09-20',
  'base_currency': 'USD',
  'lifecycle_stage': 'PLANNING',
  'created_at_utc': '2026-09-01T00:00:00Z',
  'updated_at_utc': '2026-09-01T00:00:00Z',
  'created_by': '22222222-2222-4222-8222-222222222222',
  'updated_by': '22222222-2222-4222-8222-222222222222',
  'version': version,
  'settings': <String, Object?>{},
  'is_deleted': false,
});

class MemoryCache implements EventCache {
  EventSnapshot? snapshot;
  @override
  Future<EventSnapshot?> read() async => snapshot;
  @override
  Future<void> write(EventSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

class FakeRepository implements EventRepository {
  final notifications = StreamController<RepositorySignal>.broadcast();
  List<Event> rows = [sample()];
  CloudFailureKind? failure;
  int writes = 0, reads = 0;
  Completer<List<Event>>? blockedRead;
  Completer<Event>? blockedWrite;
  @override
  Stream<RepositorySignal> get signals => notifications.stream;
  @override
  Future<List<Event>> readAll() async {
    reads++;
    if (failure != null) throw CloudFailure(failure!);
    if (blockedRead != null) {
      final f = blockedRead!;
      blockedRead = null;
      return f.future;
    }
    return List.of(rows);
  }

  @override
  Future<Event> rename(String id, int expectedVersion, String name) async {
    writes++;
    if (blockedWrite != null) return blockedWrite!.future;
    if (failure != null) throw CloudFailure(failure!);
    if (rows.single.version != expectedVersion) {
      throw const CloudFailure(CloudFailureKind.conflict);
    }
    rows = [sample(expectedVersion + 1, name)];
    return rows.single;
  }

  @override
  Future<Event> create(NewEvent input) async {
    writes++;
    return sample();
  }

  @override
  Future<void> dispose() => notifications.close();
}

Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeRepository repo;
  late MemoryCache cache;
  late EventController controller;
  setUp(() {
    repo = FakeRepository();
    cache = MemoryCache();
    controller = EventController(
      repo,
      cache,
      pollInterval: const Duration(hours: 1),
    );
  });
  tearDown(() async {
    await controller.close();
  });
  test(
    'Offline cached reads disable writes and reconnect replaces cache',
    () async {
      cache.snapshot = EventSnapshot([sample()], DateTime.now().toUtc());
      repo.failure = CloudFailureKind.unavailable;
      await controller.start();
      expect(controller.state.events.single.name, 'Uman');
      expect(controller.state.canEdit, false);
      expect(await controller.rename(sample(), 'offline'), false);
      expect(repo.writes, 0);
      repo.failure = null;
      repo.rows = [sample(2, 'Yosef')];
      repo.notifications.add(RepositorySignal.connected);
      await settle();
      expect(controller.state.events.single.name, 'Yosef');
      expect(controller.state.online, true);
      expect(cache.snapshot!.events.single.version, 2);
    },
  );
  test(
    'Realtime invalidation replaces canonical state without manual refresh',
    () async {
      await controller.start();
      repo.rows = [sample(2, 'Remote')];
      repo.notifications.add(RepositorySignal.changed);
      await settle();
      expect(controller.state.events.single.name, 'Remote');
    },
  );
  test('Stale write remains conflict after canonical reload', () async {
    await controller.start();
    final base = controller.state.events.single;
    repo.rows = [sample(2, 'Other administrator')];
    expect(await controller.rename(base, 'My draft'), false);
    expect(controller.state.saveStatus, SaveStatus.conflict);
    expect(controller.state.events.single.name, 'Other administrator');
  });
  test(
    'Save is not successful before server confirmation; double submit blocked',
    () async {
      await controller.start();
      repo.blockedWrite = Completer<Event>();
      final operation = controller.rename(sample(), 'Draft');
      await settle();
      expect(controller.state.saveStatus, SaveStatus.saving);
      expect(await controller.rename(sample(), 'Double'), false);
      repo.rows = [sample(2, 'Draft')];
      repo.blockedWrite!.complete(repo.rows.single);
      expect(await operation, true);
      expect(controller.state.saveStatus, SaveStatus.synced);
      expect(repo.writes, 1);
    },
  );
  test('Invalidation during an in-flight read causes a second read', () async {
    await controller.start();
    final pending = Completer<List<Event>>();
    repo.blockedRead = pending;
    final refresh = controller.reconcile();
    repo.rows = [sample(3, 'Latest')];
    repo.notifications.add(RepositorySignal.changed);
    await settle();
    pending.complete([sample(2, 'Intermediate')]);
    await refresh;
    await settle();
    expect(controller.state.events.single.version, 3);
  });
  test('Revocation replaces old cache with empty authorized scope', () async {
    await controller.start();
    repo.rows = [];
    await controller.reconcile();
    expect(controller.state.events, isEmpty);
    expect(cache.snapshot!.events, isEmpty);
  });
  test('Auth failure clears cached sensitive rows', () async {
    await controller.start();
    repo.failure = CloudFailureKind.unauthorized;
    await controller.reconcile();
    expect(controller.state.events, isEmpty);
    expect(cache.snapshot, isNull);
    expect(controller.state.canEdit, false);
  });
  test('Disposal while reading cannot repopulate cache', () async {
    await controller.start();
    final pending = Completer<List<Event>>();
    repo.blockedRead = pending;
    final read = controller.reconcile();
    final closing = controller.close();
    pending.complete([sample(7, 'Late')]);
    await read;
    await closing;
    expect(cache.snapshot!.events.single.version, 1);
  });
  test('Expired cached rows are not shown while offline', () async {
    cache.snapshot = EventSnapshot([
      sample(),
    ], DateTime.now().toUtc().subtract(const Duration(days: 2)));
    repo.failure = CloudFailureKind.unavailable;
    await controller.start();
    expect(controller.state.events, isEmpty);
  });
}
