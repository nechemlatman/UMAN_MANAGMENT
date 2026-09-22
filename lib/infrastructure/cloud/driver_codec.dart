import '../../domain/entities/driver.dart';

Driver decodeDriver(Map<String, dynamic> json) {
  return Driver(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    fullName: (json['full_name'] as String?) ?? '',
    phoneNumber: (json['phone_number'] as String?) ?? '',
    licenseNumber: (json['license_number'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    status: DriverStatus.fromCode((json['status'] as String?) ?? 'ACTIVE'),
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
