import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/flights_controller.dart';
import 'package:uman_event_manager/application/people_controller.dart';
import 'package:uman_event_manager/domain/entities/person.dart';
import 'package:uman_event_manager/domain/entities/flight.dart';
import 'package:uman_event_manager/presentation/flights/flight_editor_page.dart';
import 'package:uman_event_manager/presentation/people/person_editor.dart';
import 'package:uman_event_manager/presentation/events/event_editor.dart';
import 'package:uman_event_manager/presentation/forms/optional_civil_date.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache, sample;
import 'support/flights_fakes.dart';
import 'support/people_fakes.dart';

void main() {
  testWidgets('Flight editor saves empty DRAFT without invented schedule', (
    tester,
  ) async {
    final events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    final repo = FakeFlightsRepository();
    final controller = FlightsController(repo, events);
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(home: FlightEditorPage(controller: controller)),
    );
    await tester.scrollUntilVisible(
      find.text('Save Flight'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Flight'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.saved!.status, FlightStatus.draft);
    expect(repo.saved!.airline, isNull);
    expect(repo.saved!.flightNumber, isNull);
    expect(repo.saved!.scheduledDepartureUtc, isNull);
    expect(repo.saved!.scheduledArrivalUtc, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(controller.close);
    await tester.runAsync(events.close);
  });
  testWidgets('Event uses shared range and cancelling does not change dates', (
    tester,
  ) async {
    final events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    await tester.pumpWidget(
      MaterialApp(
        home: EventEditor(controller: events, base: sample()),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Event dates'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Event dates'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    final range = tester.widget<OptionalCivilDateRangeField>(
      find.byType(OptionalCivilDateRangeField),
    );
    expect(range.start.toString(), sample().startDate.toString());
    expect(range.end.toString(), sample().endDate.toString());
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(events.close);
  });
  testWidgets(
    'People birth and passport calendars cancel, select and clear to null',
    (tester) async {
      final events = EventController(FakeRepository(), MemoryCache());
      await events.start();
      final repo = FakePeopleRepository();
      final controller = PeopleController(repo, events);
      await controller.start();
      await tester.pumpWidget(
        MaterialApp(
          home: PersonEditor(controller: controller, base: repo.person),
        ),
      );
      for (final label in ['Passport expiry', 'Date of birth']) {
        final finder = find.ancestor(
          of: find.textContaining('$label:'),
          matching: find.byType(OutlinedButton),
        );
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Clear $label'));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.text('Save person'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save person'));
      await tester.pumpAndSettle();
      expect(repo.lastInput![PersonField.dateOfBirth], isNull);
      expect(repo.lastInput![PersonField.passportExpirationDate], isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(controller.close);
      await tester.runAsync(events.close);
    },
  );
}
