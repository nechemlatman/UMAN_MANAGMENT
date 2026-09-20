import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/people_controller.dart';
import 'package:uman_event_manager/domain/entities/person.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache, settle;
import 'support/people_fakes.dart';

void main() {
  late FakeRepository eventRepo;
  late EventController events;
  late FakePeopleRepository repo;
  late PeopleController controller;
  setUp(() async {
    eventRepo = FakeRepository();
    events = EventController(
      eventRepo,
      MemoryCache(),
      pollInterval: const Duration(hours: 1),
    );
    await events.start();
    repo = FakePeopleRepository();
    controller = PeopleController(
      repo,
      events,
      pollInterval: const Duration(hours: 1),
    );
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  test(
    'initial, loading, data, empty and error states reflect canonical reads',
    () async {
      final states = <PeopleLoad>[];
      final sub = controller.stream.listen((s) => states.add(s.load));
      await controller.start();
      expect(states, contains(PeopleLoad.loading));
      expect(controller.state.load, PeopleLoad.data);
      repo.rows = [];
      await controller.reconcile();
      expect(controller.state.load, PeopleLoad.empty);
      repo.readFailure = CloudFailureKind.unavailable;
      await controller.reconcile();
      expect(controller.state.load, PeopleLoad.error);
      expect(controller.state.canWrite, isFalse);
      await sub.cancel();
    },
  );
  test(
    'repeated start and duplicate notifications keep one subscription and one row',
    () async {
      await controller.start();
      await controller.start();
      repo.rows = [personFixture().summary, personFixture().summary];
      for (var i = 0; i < 10; i++) {
        repo.notifications.add(RepositorySignal.changed);
      }
      await settle();
      expect(controller.state.rows.length, 1);
      expect(repo.notifications.hasListener, isTrue);
      await controller.close();
      expect(repo.disposed, 1);
    },
  );
  test(
    'invalidation during blocked fetch reruns and late responses cannot overwrite search',
    () async {
      await controller.start();
      final pending = Completer<List<PersonSummary>>();
      repo.blockedRead = pending;
      final refresh = controller.reconcile();
      controller.search('דוד');
      repo.notifications.add(RepositorySignal.changed);
      await settle();
      pending.complete([]);
      await refresh;
      await settle();
      expect(controller.state.rows.length, 1);
      expect(repo.lastQuery, 'דוד');
    },
  );
  test(
    'canonical replacement reflects remote delete and reconnect recovery',
    () async {
      await controller.start();
      repo.rows = [];
      repo.notifications.add(RepositorySignal.connected);
      await settle();
      expect(controller.state.rows, isEmpty);
      expect(controller.state.realtimeConnected, isTrue);
      repo.rows = [personFixture(version: 5).summary];
      repo.notifications.add(RepositorySignal.connected);
      await settle();
      expect(controller.state.rows.single.version, 5);
      repo.notifications.add(RepositorySignal.disconnected);
      await settle();
      expect(controller.state.realtimeConnected, isFalse);
    },
  );
  test(
    'access revocation clears rows and protected details immediately',
    () async {
      await controller.start();
      await controller.select(personFixture().summary.id);
      expect(controller.state.person, isNotNull);
      eventRepo.rows = [];
      await events.reconcile();
      await settle();
      expect(controller.state.rows, isEmpty);
      expect(controller.state.person, isNull);
      expect(controller.state.accessible, isFalse);
      expect(controller.state.canWrite, isFalse);
    },
  );
  test(
    'server authorization failure hides open editors even before Event refresh',
    () async {
      await controller.start();
      repo.readFailure = CloudFailureKind.unauthorized;
      await controller.reconcile();
      expect(controller.state.accessible, isFalse);
      expect(controller.state.rows, isEmpty);
    },
  );
  test('foreign-event result is rejected and cleared', () async {
    repo.rows = [personFixture(eventId: 'other').summary];
    await controller.start();
    expect(controller.state.rows, isEmpty);
    expect(controller.state.failure, CloudFailureKind.unauthorized);
  });
  test(
    'conflict reconciles without successful save; request key is stable on retry',
    () async {
      await controller.start();
      repo.writeFailure = CloudFailureKind.conflict;
      final input = personFixture().input;
      expect(await controller.save(input, requestId: 'stable'), isFalse);
      expect(controller.state.save, SaveStatus.conflict);
      expect(controller.state.rows.single.firstName, 'David');
      repo.writeFailure = null;
      expect(await controller.save(input, requestId: 'stable'), isTrue);
      expect(repo.request, 'stable');
    },
  );
  test('disposing during pending fetch prevents late emissions', () async {
    final pending = Completer<List<PersonSummary>>();
    repo.blockedRead = pending;
    final started = controller.start();
    await controller.close();
    pending.complete([personFixture().summary]);
    await started;
    expect(controller.isClosed, isTrue);
    expect(repo.disposed, 1);
  });
  test('pagination uses bounded event-scoped reads', () async {
    await controller.start();
    await controller.page(2);
    expect(repo.lastOffset, 100);
    expect(controller.repository.eventId, peopleEvent);
  });
}
