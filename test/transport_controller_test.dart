import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/drivers_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/vehicles_controller.dart';
import 'package:uman_event_manager/domain/entities/driver.dart';
import 'package:uman_event_manager/domain/entities/vehicle.dart';
import 'package:uman_event_manager/domain/value_objects/uuid_v4.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/people_fakes.dart' show peopleEvent;
import 'support/transport_fakes.dart';

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

  group('DriversController', () {
    test('saveDriver creates driver and list reflects it', () async {
      const input = DriverInput(
        fullName: 'Shlomo Reuven',
        phoneNumber: '0541112233',
        licenseNumber: 'L-9988',
        status: DriverStatus.active,
      );

      final ok = await driversController.saveDriver(
        input,
        requestId: UuidV4.generate(),
      );

      expect(ok, true);
      expect(driversController.state.drivers.length, 1);
      expect(driversController.state.drivers.first.fullName, 'Shlomo Reuven');
    });

    test('deleteDriver soft deletes driver', () async {
      final reqId = UuidV4.generate();
      await driversController.saveDriver(
        const DriverInput(fullName: 'ToDelete'),
        requestId: reqId,
      );

      final driver = driversController.state.drivers.first;
      final ok = await driversController.deleteDriver(driver);

      expect(ok, true);
      expect(driversController.state.drivers, isEmpty);

      driversController.toggleIncludeDeleted();
      await driversController.refresh();
      expect(driversController.state.drivers.length, 1);
      expect(driversController.state.drivers.first.isDeleted, true);
    });
  });

  group('VehiclesController', () {
    test('saveVehicle creates vehicle and search filters it', () async {
      await vehiclesController.saveVehicle(
        const VehicleInput(name: 'Sprinter A', type: VehicleType.van, capacity: 16),
        requestId: UuidV4.generate(),
      );
      await vehiclesController.saveVehicle(
        const VehicleInput(name: 'Bus Deluxe', type: VehicleType.bus, capacity: 50),
        requestId: UuidV4.generate(),
      );

      expect(vehiclesController.state.vehicles.length, 2);

      vehiclesController.updateQuery('Deluxe');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(vehiclesController.state.vehicles.length, 1);
      expect(vehiclesController.state.vehicles.first.name, 'Bus Deluxe');
    });
  });
}
