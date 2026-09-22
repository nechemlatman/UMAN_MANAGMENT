import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/drivers_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/vehicles_controller.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/people_fakes.dart' show peopleEvent;
import 'support/transport_fakes.dart';
import 'package:uman_event_manager/presentation/transport/drivers_page.dart';
import 'package:uman_event_manager/presentation/transport/vehicles_page.dart';

void main() {
  late FakeTransportRepository repository;
  late EventController events;
  late DriversController driversController;
  late VehiclesController vehiclesController;

  setUp(() async {
    repository = FakeTransportRepository();
    events = EventController(FakeRepository(), MemoryCache());
    await events.start();

    driversController = DriversController.forEvent(
      repository,
      peopleEvent,
      events,
    );
    vehiclesController = VehiclesController.forEvent(
      repository,
      peopleEvent,
      events,
    );

    driversController.start();
    vehiclesController.start();
  });

  tearDown(() async {
    await driversController.close();
    await vehiclesController.close();
    await events.close();
  });

  testWidgets('DriversPage renders and allows adding driver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriversPage(controller: driversController),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drivers'), findsOneWidget);
    expect(find.text('No drivers found'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Driver'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Yakov Moshe');
    await tester.tap(find.text('Save Driver'));
    await tester.pumpAndSettle();

    expect(find.text('Yakov Moshe'), findsOneWidget);
  });

  testWidgets('VehiclesPage renders and allows adding vehicle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VehiclesPage(controller: vehiclesController),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicles'), findsOneWidget);
    expect(find.text('No vehicles found'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Vehicle'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Sprinter 01');
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Sprinter 01'), findsOneWidget);
  });
}
