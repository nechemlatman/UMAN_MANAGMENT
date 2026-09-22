import '../../domain/entities/vehicle.dart';

Vehicle decodeVehicle(Map<String, dynamic> json) {
  return Vehicle(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    name: (json['name'] as String?) ?? '',
    type: VehicleType.fromCode((json['vehicle_type'] as String?) ?? 'VAN'),
    licensePlate: (json['license_plate'] as String?) ?? '',
    capacity: (json['capacity'] as num?)?.toInt() ?? 1,
    status: VehicleStatus.fromCode((json['status'] as String?) ?? 'AVAILABLE'),
    notes: (json['notes'] as String?) ?? '',
    isDeleted: (json['is_deleted'] as bool?) ?? false,
    version: (json['version'] as num?)?.toInt() ?? 1,
    createdAtUtc: json['created_at_utc'] != null
        ? DateTime.parse(json['created_at_utc'] as String).toUtc()
        : DateTime.now().toUtc(),
    updatedAtUtc: json['updated_at_utc'] != null
        ? DateTime.parse(json['updated_at_utc'] as String).toUtc()
        : DateTime.now().toUtc(),
    createdBy: (json['created_by'] as String?) ?? '',
    updatedBy: (json['updated_by'] as String?) ?? '',
  );
}
