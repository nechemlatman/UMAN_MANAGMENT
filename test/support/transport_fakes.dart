import 'package:uman_event_manager/domain/entities/driver.dart';
import 'package:uman_event_manager/domain/entities/vehicle.dart';
import 'package:uman_event_manager/domain/repositories/transport_repository.dart';
import 'package:uman_event_manager/domain/value_objects/uuid_v4.dart';

class FakeTransportRepository implements TransportRepository {
  final Map<String, Driver> driversStore = {};
  final Map<String, Vehicle> vehiclesStore = {};

  // --- DRIVERS ---
  @override
  Future<List<Driver>> listDrivers(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  }) async {
    return driversStore.values.where((d) {
      if (d.eventId != eventId) return false;
      if (!includeDeleted && d.isDeleted) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final nameMatch = d.fullName.toLowerCase().contains(q);
        final phoneMatch = d.phoneNumber.toLowerCase().contains(q);
        final licenseMatch = d.licenseNumber.toLowerCase().contains(q);
        if (!nameMatch && !phoneMatch && !licenseMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Driver?> readDriver(String eventId, String driverId) async {
    final driver = driversStore[driverId];
    if (driver == null || driver.eventId != eventId) return null;
    return driver;
  }

  @override
  Future<String> saveDriver(
    String eventId,
    DriverInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
    final now = DateTime.now().toUtc();
    final driverId = id ?? UuidV4.generate();

    if (id != null) {
      final existing = driversStore[id];
      if (existing == null || existing.version != expectedVersion) {
        throw Exception('Stale driver write');
      }
      final updated = existing.copyWith(
        fullName: input.fullName,
        phoneNumber: input.phoneNumber,
        licenseNumber: input.licenseNumber,
        notes: input.notes,
        status: input.status,
        version: existing.version + 1,
      );
      driversStore[id] = updated;
      return id;
    } else {
      final driver = Driver(
        id: driverId,
        eventId: eventId,
        fullName: input.fullName,
        phoneNumber: input.phoneNumber,
        licenseNumber: input.licenseNumber,
        notes: input.notes,
        status: input.status,
        isDeleted: false,
        version: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );
      driversStore[driverId] = driver;
      return driverId;
    }
  }

  @override
  Future<void> deleteDriver(
    String eventId,
    String driverId, {
    required int expectedVersion,
  }) async {
    final existing = driversStore[driverId];
    if (existing == null || existing.version != expectedVersion) {
      throw Exception('Stale driver delete');
    }
    driversStore[driverId] = existing.copyWith(
      isDeleted: true,
      version: existing.version + 1,
    );
  }

  // --- VEHICLES ---
  @override
  Future<List<Vehicle>> listVehicles(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  }) async {
    return vehiclesStore.values.where((v) {
      if (v.eventId != eventId) return false;
      if (!includeDeleted && v.isDeleted) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final nameMatch = v.name.toLowerCase().contains(q);
        final plateMatch = v.licensePlate.toLowerCase().contains(q);
        final typeMatch = v.type.displayName.toLowerCase().contains(q);
        if (!nameMatch && !plateMatch && !typeMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Vehicle?> readVehicle(String eventId, String vehicleId) async {
    final vehicle = vehiclesStore[vehicleId];
    if (vehicle == null || vehicle.eventId != eventId) return null;
    return vehicle;
  }

  @override
  Future<String> saveVehicle(
    String eventId,
    VehicleInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
    final now = DateTime.now().toUtc();
    final vehicleId = id ?? UuidV4.generate();

    if (id != null) {
      final existing = vehiclesStore[id];
      if (existing == null || existing.version != expectedVersion) {
        throw Exception('Stale vehicle write');
      }
      final updated = existing.copyWith(
        name: input.name,
        type: input.type,
        licensePlate: input.licensePlate,
        capacity: input.capacity,
        status: input.status,
        notes: input.notes,
        version: existing.version + 1,
      );
      vehiclesStore[id] = updated;
      return id;
    } else {
      final vehicle = Vehicle(
        id: vehicleId,
        eventId: eventId,
        name: input.name,
        type: input.type,
        licensePlate: input.licensePlate,
        capacity: input.capacity,
        status: input.status,
        notes: input.notes,
        isDeleted: false,
        version: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );
      vehiclesStore[vehicleId] = vehicle;
      return vehicleId;
    }
  }

  @override
  Future<void> deleteVehicle(
    String eventId,
    String vehicleId, {
    required int expectedVersion,
  }) async {
    final existing = vehiclesStore[vehicleId];
    if (existing == null || existing.version != expectedVersion) {
      throw Exception('Stale vehicle delete');
    }
    vehiclesStore[vehicleId] = existing.copyWith(
      isDeleted: true,
      version: existing.version + 1,
    );
  }
}
