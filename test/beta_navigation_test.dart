import 'package:uman_event_manager/application/flights_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/presentation/flights/flight_details_page.dart';
import 'package:uman_event_manager/presentation/flights/flights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/presentation/events/event_shell.dart';
import 'package:uman_event_manager/presentation/design_system.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/people_fakes.dart';
import 'support/flights_fakes.dart';
import 'support/transport_fakes.dart';
import 'support/trip_fakes.dart';
import 'support/accommodation_fakes.dart';

void main() {
  testWidgets('Flight load failure offers retry and recovers', (tester) async {
    final events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    final repo = FakeFlightsRepository();
    final controller = FlightsController(repo, events);
    await controller.start();
    repo.failure = CloudFailureKind.unavailable;
    await tester.pumpWidget(
      MaterialApp(
        home: FlightDetailsPage(
          controller: controller,
          peopleRepository: FakePeopleRepository(),
          flightId: flightFixture().id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    repo.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit flight'), findsOneWidget);
    expect(find.byTooltip('Delete flight'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await controller.close();
      await events.close();
    });
  });
  testWidgets('Empty flight search explains no matches', (tester) async {
    final events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    final repo = FakeFlightsRepository()..flights = [];
    final controller = FlightsController(repo, events);
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlightsPage(
            controller: controller,
            peopleRepository: FakePeopleRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No flights yet. Add the first flight.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('flights-search')),
      'missing',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(
      find.text('No matching flights. Try another search.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await controller.close();
      await events.close();
    });
  });
  for (final direction in TextDirection.values) {
    for (final brightness in Brightness.values) {
      testWidgets('Beta phone navigation $direction $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final events = EventController(FakeRepository(), MemoryCache());
        await events.start();
        final people = FakePeopleRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme(brightness),
            builder: (context, child) =>
                Directionality(textDirection: direction, child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Select event'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EventShell(
                        events: events,
                        eventId: peopleEvent,
                        peopleFactory: (_) => people,
                        flightsFactory: (_) => FakeFlightsRepository(),
                        transportFactory: (_) => FakeTransportRepository(),
                        tripsFactory: (_) => FakeTripsRepository(),
                        accommodationFactory: (_) =>
                            FakeAccommodationRepository(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Select event'));
        await tester.pumpAndSettle();
        expect(find.text('Add person'), findsOneWidget);
        Future<void> keyboardCheck() async {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pump();
        }

        await keyboardCheck();
        Future<void> open(String label) async {
          await tester.tap(find.byTooltip('Open navigation menu').first);
          await tester.pumpAndSettle();
          for (final future in [
            'Control Center / Dashboard',
            'Tasks',
            'Apartment Issues',
            'Finance',
            'Unresolved Items',
          ]) {
            expect(find.text(future), findsNothing);
          }
          await tester.tap(find.widgetWithText(ListTile, label));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await open('Flights');
        expect(find.text('Add Flight'), findsOneWidget);
        await keyboardCheck();
        await open('Transport');
        expect(find.text('Trips'), findsWidgets);
        await tester.tap(find.widgetWithText(Tab, 'Drivers'));
        await tester.pumpAndSettle();
        expect(find.text('Add Driver'), findsOneWidget);
        await keyboardCheck();
        expect(find.byType(BackButton), findsNothing);
        await tester.tap(find.widgetWithText(Tab, 'Vehicles'));
        await tester.pumpAndSettle();
        expect(find.text('Add Vehicle'), findsOneWidget);
        await keyboardCheck();
        expect(tester.takeException(), isNull);
        await open('Accommodation');
        expect(find.text('New apartment'), findsOneWidget);
        await keyboardCheck();
        await open('Event Settings');
        expect(find.text('Edit event'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await open('People');
        expect(find.text('Add person'), findsOneWidget);
        await open('Return to Events');
        expect(find.text('Select event'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(events.close);
      });
    }
  }
}
