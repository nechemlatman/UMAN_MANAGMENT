import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/entities/event.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';

import '../support/fixtures.dart';

class _Cache implements EventCache {
  EventSnapshot? snapshot;
  bool readFails = false;
  Completer<void>? clearing;

  @override
  Future<EventSnapshot?> read() async {
    if (readFails) throw StateError('Storage unavailable');
    return snapshot;
  }

  @override
  Future<void> write(EventSnapshot value) async => snapshot = value;

  @override
  Future<void> clear() async {
    await clearing?.future;
    snapshot = null;
  }
}

class _Repository implements EventRepository {
  final notifications = StreamController<RepositorySignal>.broadcast();
  Object? failure;
  int reads = 0;
  Completer<List<Event>>? pending;

  @override
  Stream<RepositorySignal> get signals => notifications.stream;

  @override
  Future<List<Event>> readAll() async {
    reads++;
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return [sampleEvent()];
  }

  @override
  Future<Event> create(NewEvent input) => throw UnimplementedError();

  @override
  Future<Event> rename(String id, int expectedVersion, String name) =>
      throw UnimplementedError();

  @override
  Future<void> dispose() => notifications.close();
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Cache cache;
  late _Repository repository;
  late EventController controller;

  setUp(() {
    cache = _Cache();
    repository = _Repository();
    controller = EventController(
      repository,
      cache,
      pollInterval: const Duration(hours: 1),
    );
  });
  tearDown(() => controller.close());

  test(
    'cache read failure does not prevent authenticated server loading',
    () async {
      cache.readFails = true;
      await controller.start();
      expect(repository.reads, 1);
      expect(controller.state.events.single, sampleEvent());
      expect(controller.state.online, isTrue);
    },
  );

  for (final age in [const Duration(days: 2), const Duration(hours: -1)]) {
    test(
      'invalid cache age $age is never exposed before a server response',
      () async {
        cache.snapshot = EventSnapshot([
          sampleEvent(),
        ], DateTime.now().toUtc().subtract(age));
        repository.pending = Completer<List<Event>>();
        final states = <EventState>[];
        final subscription = controller.stream.listen(states.add);
        final starting = controller.start();
        await _settle();
        final exposed = controller.state.events.isNotEmpty;
        repository.pending!.complete([]);
        await starting;
        await subscription.cancel();
        expect(exposed, isFalse);
        expect(states.every((state) => state.events.isEmpty), isTrue);
      },
    );
  }

  test(
    'unknown read failure cannot keep an expired initial snapshot visible',
    () async {
      cache.snapshot = EventSnapshot([
        sampleEvent(),
      ], DateTime.now().toUtc().subtract(const Duration(days: 2)));
      repository.failure = StateError('Unexpected adapter failure');
      await controller.start();
      expect(controller.state.events, isEmpty);
      expect(controller.state.synchronizedAt, isNull);
      expect(controller.state.failure, CloudFailureKind.unknown);
      expect(controller.state.canEdit, isFalse);
    },
  );

  test(
    'authorization failure hides rows before slow cache deletion finishes',
    () async {
      await controller.start();
      cache.clearing = Completer<void>();
      repository.failure = const CloudFailure(CloudFailureKind.unauthorized);
      final refreshing = controller.reconcile();
      await _settle();
      final visibleWhileClearing = controller.state.events.isNotEmpty;
      final editableWhileClearing = controller.state.canEdit;
      cache.clearing!.complete();
      await refreshing;
      expect(visibleWhileClearing, isFalse);
      expect(editableWhileClearing, isFalse);
      expect(controller.state.synchronizedAt, isNull);
      expect(cache.snapshot, isNull);
    },
  );
}
