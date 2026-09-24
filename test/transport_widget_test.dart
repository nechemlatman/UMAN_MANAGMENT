import 'package:flutter/material.dart';
import 'package:uman_event_manager/domain/entities/driver.dart';
import 'package:uman_event_manager/domain/entities/vehicle.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
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

    await driversController.start();
    await vehiclesController.start();
  });

  tearDown(() async {
    await driversController.close();
    await vehiclesController.close();
    await events.close();
  });

  testWidgets('DriversPage renders and allows adding driver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DriversPage(controller: driversController)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drivers'), findsOneWidget);
    expect(find.text('No drivers found'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Driver'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Yakov Moshe');
    await tester.scrollUntilVisible(
      find.text('Save Driver'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Driver'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Yakov Moshe'), findsOneWidget);
  });

  testWidgets('VehiclesPage renders and allows adding vehicle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: VehiclesPage(controller: vehiclesController)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicles'), findsOneWidget);
    expect(find.text('No vehicles found'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Vehicle'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Sprinter 01');
    await tester.scrollUntilVisible(
      find.text('Save Vehicle'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Save Vehicle'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Vehicle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sprinter 01'), findsOneWidget);
    expect(repository.vehiclesStore.values.single.name, 'Sprinter 01');
    expect(find.text('Save Vehicle'), findsNothing);
  });

  for (final rtl in [false, true]) {
    testWidgets(
      'deleted drivers and vehicles can be restored in ${rtl ? "RTL" : "LTR"}',
      (tester) async {
        await driversController.saveDriver(
          const DriverInput(fullName: 'Restore driver'),
          requestId: 'd',
        );
        await driversController.deleteDriver(
          driversController.state.drivers.single,
        );
        driversController.toggleIncludeDeleted();
        await driversController.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: DriversPage(controller: driversController),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Restore driver'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Restore Driver'));
        await tester.pumpAndSettle();
        expect(repository.driversStore.values.single.isDeleted, false);
        expect(find.text('No drivers found'), findsOneWidget);
        await vehiclesController.saveVehicle(
          const VehicleInput(name: 'Restore vehicle'),
          requestId: 'v',
        );
        await vehiclesController.deleteVehicle(
          vehiclesController.state.vehicles.single,
        );
        vehiclesController.toggleIncludeDeleted();
        await vehiclesController.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: VehiclesPage(controller: vehiclesController),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Restore vehicle'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Restore Vehicle'));
        await tester.pumpAndSettle();
        expect(repository.vehiclesStore.values.single.isDeleted, false);
      },
    );
  }

  testWidgets('conflict preserves draft and shows recovery instruction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DriversPage(controller: driversController)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'My draft');
    repository.writeFailure = CloudFailureKind.conflict;
    await tester.scrollUntilVisible(
      find.text('Save Driver'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Driver'));
    await tester.pumpAndSettle();
    expect(find.text('Add Driver'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My draft'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('My draft'), findsOneWidget);
    expect(find.textContaining('Your draft is preserved'), findsOneWidget);
  });
}
