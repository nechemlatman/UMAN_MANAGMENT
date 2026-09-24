import '../../domain/entities/driver.dart';

Driver decodeDriver(Map<String, dynamic> json) {
  return Driver(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    fullName: (json['full_name'] as String?) ?? '',
    phoneNumber: (json['phone_number'] as String?) ?? '',
    licenseNumber: (json['license_number'] as String?) ?? '',
    whatsappPhone: (json['whatsapp_phone'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    status: DriverStatus.fromCode(json['status'] as String),
    isDeleted: (json['is_deleted'] as bool?) ?? false,
    version: (json['version'] as num).toInt(),
    createdAtUtc: DateTime.parse(json['created_at_utc'] as String).toUtc(),
    updatedAtUtc: DateTime.parse(json['updated_at_utc'] as String).toUtc(),
    createdBy: (json['created_by'] as String?) ?? '',
    updatedBy: (json['updated_by'] as String?) ?? '',
  );
}
