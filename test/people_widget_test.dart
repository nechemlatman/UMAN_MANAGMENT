import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/people_controller.dart';
import 'package:uman_event_manager/domain/entities/person.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/presentation/events/event_shell.dart';
import 'package:uman_event_manager/presentation/people/person_editor.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/people_fakes.dart';
import 'support/flights_fakes.dart';
import 'support/transport_fakes.dart';

void main() {
  testWidgets(
    'shell opens People and disposes active event repository when leaving',
    (tester) async {
      final events = EventController(FakeRepository(), MemoryCache());
      await events.start();
      final repo = FakePeopleRepository();
      final flightsRepo = FakeFlightsRepository();
      final transportRepo = FakeTransportRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: EventShell(
            events: events,
            eventId: peopleEvent,
            peopleFactory: (_) => repo,
            flightsFactory: (_) => flightsRepo,
            transportFactory: (_) => transportRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open People'));
      await tester.pumpAndSettle();
      expect(find.textContaining('David'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await events.close();
      });
      expect(repo.disposed, 1);
      expect(flightsRepo.disposed, 1);
    },
  );
  testWidgets(
    'draft survives remote edits and stale save; revocation hides fields',
    (tester) async {
      final eventRepo = FakeRepository();
      final events = EventController(eventRepo, MemoryCache());
      await events.start();
      final repo = FakePeopleRepository();
      final controller = PeopleController(repo, events);
      await controller.start();
      await controller.select(personFixture().summary.id);
      await tester.pumpWidget(
        MaterialApp(
          home: PersonEditor(controller: controller, base: personFixture()),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey(PersonField.firstName)),
        'My draft',
      );
      repo.person = personFixture(version: 2, name: 'Other manager');
      repo.rows = [repo.person.summary];
      repo.notifications.add(RepositorySignal.changed);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey(PersonField.firstName)),
            )
            .controller!
            .text,
        'My draft',
      );
      repo.writeFailure = CloudFailureKind.conflict;
      await tester.scrollUntilVisible(
        find.text('Save person'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save person'));
      await tester.pumpAndSettle();
      expect(repo.lastInput![PersonField.firstName], 'My draft');
      expect(find.textContaining('Your draft is kept'), findsOneWidget);
      eventRepo.rows = [];
      await events.reconcile();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await controller.close();
        await events.close();
      });
    },
  );
  testWidgets(
    'invalid form submits no mutation and explains required first name',
    (tester) async {
      final events = EventController(FakeRepository(), MemoryCache());
      await events.start();
      final repo = FakePeopleRepository();
      final controller = PeopleController(repo, events);
      await controller.start();
      await tester.pumpWidget(
        MaterialApp(home: PersonEditor(controller: controller)),
      );
      await tester.scrollUntilVisible(
        find.text('Save person'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save person'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey(PersonField.firstName)),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('First name is required.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await controller.close();
        await events.close();
      });
    },
  );
}
