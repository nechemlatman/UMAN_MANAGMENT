import 'dart:async';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
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
  late FakeRepository eventRepository;
  late DriversController driversController;
  late VehiclesController vehiclesController;

  setUp(() async {
    repository = FakeTransportRepository();
    eventRepository = FakeRepository();
    events = EventController(eventRepository, MemoryCache());
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

  group('DriversController', () {
    test('saveDriver creates driver and list reflects it', () async {
      const input = DriverInput(
        fullName: 'Shlomo Reuven',
        phoneNumber: '0541112233',
        licenseNumber: 'L-9988',
        status: DriverStatus.available,
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

  test('realtime reconnect and changed signals reload both canonical lists', () async {
    await driversController.saveDriver(const DriverInput(fullName: 'Before'), requestId: 'one');
    final row = driversController.state.drivers.single;
    repository.driversStore[row.id] = row.copyWith(fullName: 'Remote', version: 2);
    repository.changes.add(RepositorySignal.connected);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(driversController.state.realtimeConnected, true);
    expect(vehiclesController.state.realtimeConnected, true);
    expect(driversController.state.drivers.single.fullName, 'Remote');
    repository.changes.add(RepositorySignal.disconnected);
    await Future<void>.delayed(Duration.zero);
    expect(driversController.state.realtimeConnected, false);
    repository.changes.add(RepositorySignal.changed);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(driversController.state.drivers.single.version, 2);
  });

  test('delete and restore preserve operational data for both entities', () async {
    await driversController.saveDriver(const DriverInput(fullName: 'Driver',
      whatsappPhone: '+972123', status: DriverStatus.offDuty), requestId: 'one');
    final driver = driversController.state.drivers.single;
    await driversController.deleteDriver(driver);
    expect(await driversController.restoreDriver(repository.driversStore[driver.id]!), true);
    expect(driversController.state.drivers.single.whatsappPhone, '+972123');
    expect(driversController.state.drivers.single.status, DriverStatus.offDuty);
    await vehiclesController.saveVehicle(const VehicleInput(name: 'Bus', color: 'Blue',
      status: VehicleStatus.inUse), requestId: 'two');
    final vehicle = vehiclesController.state.vehicles.single;
    await vehiclesController.deleteVehicle(vehicle);
    expect(await vehiclesController.restoreVehicle(repository.vehiclesStore[vehicle.id]!), true);
    expect(vehiclesController.state.vehicles.single.color, 'Blue');
    expect(vehiclesController.state.vehicles.single.version, 3);
  });

  test('CAS conflicts reconcile and remain explicit through periodic reads', () async {
    await driversController.saveDriver(const DriverInput(fullName: 'Before'), requestId: 'one');
    final base = driversController.state.drivers.single;
    repository.driversStore[base.id] = base.copyWith(fullName: 'Remote', version: 2);
    expect(await driversController.saveDriver(const DriverInput(fullName: 'Draft'),
      requestId: 'edit', base: base), false);
    expect(driversController.state.save, SaveStatus.conflict);
    expect(driversController.state.failure, CloudFailureKind.conflict);
    await driversController.refresh();
    expect(driversController.state.drivers.single.fullName, 'Remote');
    expect(driversController.state.failure, CloudFailureKind.conflict);
  });

  test('connectivity and authorization failures are distinct and disable writes', () async {
    repository.readFailure = CloudFailureKind.unavailable;
    await driversController.refresh();
    await vehiclesController.refresh();
    expect(driversController.state.failure, CloudFailureKind.unavailable);
    expect(driversController.state.canWrite, false);
    expect(vehiclesController.state.canWrite, false);
    repository.readFailure = null;
    await driversController.refresh();
    await driversController.saveDriver(const DriverInput(fullName: 'Private'), requestId: 'one');
    repository.readFailure = CloudFailureKind.unauthorized;
    await driversController.refresh();
    expect(driversController.state.drivers, isEmpty);
    expect(driversController.state.selectedDriver, isNull);
    expect(driversController.state.accessible, false);
  });

  test('revocation during a read cannot repopulate data or selection', () async {
    final gate = Completer<void>();
    repository.readGate = gate.future;
    final read = driversController.refresh();
    eventRepository.rows = [];
    await events.reconcile();
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await read;
    expect(driversController.state.accessible, false);
    expect(driversController.state.drivers, isEmpty);
    expect(repository.changes.hasListener, false);
  });

  test('invalidation during fetch reruns and close cancels subscriptions', () async {
    final gate = Completer<void>();
    repository.readGate = gate.future;
    final before = repository.reads;
    final read = driversController.refresh();
    repository.changes.add(RepositorySignal.changed);
    await Future<void>.delayed(Duration.zero);
    repository.readGate = null;
    gate.complete();
    await read;
    expect(repository.reads, greaterThan(before + 1));
    await driversController.close();
    await vehiclesController.close();
    expect(repository.disposed, true);
    expect(repository.changes.hasListener, false);
  });

  test('periodic reconciliation runs without realtime notifications', () async {
    final repo = FakeTransportRepository();
    final controller = DriversController(repo, events,
      pollInterval: const Duration(milliseconds: 10));
    await controller.start();
    final reads = repo.reads;
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(repo.reads, greaterThan(reads));
    await controller.close();
    final stoppedReads = repo.reads;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(repo.reads, stoppedReads);
  });
}
