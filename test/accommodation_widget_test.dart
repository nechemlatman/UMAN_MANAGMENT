import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/accommodation_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/entities/accommodation.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/presentation/accommodation/accommodation_pages.dart';
import 'package:uman_event_manager/presentation/design_system.dart';
import 'package:uman_event_manager/presentation/events/event_shell.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/accommodation_fakes.dart';
import 'support/people_fakes.dart';
import 'support/flights_fakes.dart';
import 'support/transport_fakes.dart';

void main() {
  late EventController events;
  late FakeAccommodationRepository repo;
  late AccommodationController controller;
  setUp(() async {
    events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    repo = FakeAccommodationRepository();
    controller = AccommodationController(repo, events);
    await controller.start();
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  for (final direction in TextDirection.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Hierarchy and persistent overlap with manager note: $direction $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = repo.data;
          repo.data = AccommodationSnapshot(
            apartments: data.apartments,
            rooms: data.rooms,
            sleepingPlaces: data.sleepingPlaces,
            people: data.people,
            assignments: [
              accRecord(
                assignmentId,
                assignmentInput(
                  locked: true,
                  notes: 'Manager approved extra mattress',
                ),
              ),
            ],
            overlaps: const [AccommodationOverlap(assignmentId, personId)],
          );
          await controller.refresh();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.theme(brightness),
              home: Directionality(
                textDirection: direction,
                child: ApartmentDetailsPage(
                  controller: controller,
                  apartmentId: aptId,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.textContaining('Room א'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.textContaining('Room א'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.textContaining('Bed A'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.textContaining('Bed A'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.textContaining('ACCOMMODATION_OVERLAP'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.textContaining('ACCOMMODATION_OVERLAP'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.textContaining('Manager approved'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.textContaining('Manager approved'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Empty long apartment form cannot save when required fields scroll away',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccommodationEditorPage(
            controller: controller,
            kind: AccommodationKind.apartment,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Draft and original CAS base survive realtime and conflict', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccommodationEditorPage(
          controller: controller,
          kind: AccommodationKind.room,
          base: repo.data.rooms.single,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Manager draft');
    repo.data = accSnapshot(version: 2);
    repo.changes.add(RepositorySignal.changed);
    await tester.pumpAndSettle();
    expect(find.text('Manager draft'), findsOneWidget);
    repo.writeFailure = CloudFailureKind.conflict;
    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.base!.version, 1);
    expect(controller.state.save, SaveStatus.conflict);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('Manager draft'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Manager draft'), findsOneWidget);
  });
  testWidgets(
    'Invalid dates and blank manager override prevent assignment write',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccommodationEditorPage(
            controller: controller,
            kind: AccommodationKind.assignment,
            base: repo.data.assignments.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Checkout date'),
        '2026-09-20',
      );
      await tester.scrollUntilVisible(
        find.text('Save'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Checkout date'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Checkout date'),
        '2026-09-24',
      );
      await tester.scrollUntilVisible(
        find.text('Manager override / locked'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Manager override / locked'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
    },
  );
  testWidgets(
    'Event shell wires Accommodation, foreground refresh and repository disposal',
    (tester) async {
      final shellRepo = FakeAccommodationRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: EventShell(
            events: events,
            eventId: accEvent,
            peopleFactory: (_) => FakePeopleRepository(),
            flightsFactory: (_) => FakeFlightsRepository(),
            transportFactory: (_) => FakeTransportRepository(),
            accommodationFactory: (_) => shellRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accommodation'));
      await tester.pumpAndSettle();
      expect(find.byType(ApartmentsPage), findsOneWidget);
      final reads = shellRepo.reads;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(shellRepo.reads, greaterThan(reads));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(shellRepo.disposed, true);
    },
  );
  testWidgets('Revoked access hides the retained draft and disables mutation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccommodationEditorPage(
          controller: controller,
          kind: AccommodationKind.room,
          base: repo.data.rooms.single,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Private draft');
    repo.readFailure = CloudFailureKind.unauthorized;
    await tester.runAsync(controller.refresh);
    await tester.pumpAndSettle();
    expect(find.text('Private draft'), findsNothing);
    expect(find.text('Access is no longer available.'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });
}
