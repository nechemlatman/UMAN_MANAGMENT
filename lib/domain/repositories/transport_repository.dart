import '../entities/driver.dart';
import '../entities/vehicle.dart';

abstract class TransportRepository {
  // --- DRIVERS ---
  Future<List<Driver>> listDrivers(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  });

  Future<Driver?> readDriver(String eventId, String driverId);

  Future<String> saveDriver(
    String eventId,
    DriverInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  });

  Future<void> deleteDriver(
    String eventId,
    String driverId, {
    required int expectedVersion,
  });

  // --- VEHICLES ---
  Future<List<Vehicle>> listVehicles(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  });

  Future<Vehicle?> readVehicle(String eventId, String vehicleId);

  Future<String> saveVehicle(
    String eventId,
    VehicleInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  });

  Future<void> deleteVehicle(
    String eventId,
    String vehicleId, {
    required int expectedVersion,
  });
}
