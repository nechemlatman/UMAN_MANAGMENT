enum DriverStatus {
  available('AVAILABLE', 'Available'),
  busy('BUSY', 'Busy'),
  unavailable('UNAVAILABLE', 'Unavailable'),
  offDuty('OFF_DUTY', 'Off Duty');

  const DriverStatus(this.code, this.displayName);
  final String code;
  final String displayName;

  static DriverStatus fromCode(String code) {
    return DriverStatus.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => throw const FormatException('Invalid driver status'),
    );
  }
}

class DriverInput {
  const DriverInput({
    required this.fullName,
    this.phoneNumber = '',
    this.whatsappPhone = '',
    this.licenseNumber = '',
    this.notes = '',
    this.status = DriverStatus.available,
  });

  final String fullName;
  final String phoneNumber;
  final String whatsappPhone;
  final String licenseNumber;
  final String notes;
  final DriverStatus status;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'whatsapp_phone': whatsappPhone,
      'license_number': licenseNumber,
      'notes': notes,
      'status': status.code,
    };
  }
}

class Driver {
  const Driver({
    required this.id,
    required this.eventId,
    required this.fullName,
    required this.phoneNumber,
    this.whatsappPhone = '',
    required this.licenseNumber,
    required this.notes,
    required this.status,
    required this.isDeleted,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String eventId;
  final String fullName;
  final String phoneNumber;
  final String whatsappPhone;
  final String licenseNumber;
  final String notes;
  final DriverStatus status;
  final bool isDeleted;
  final int version;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String createdBy;
  final String updatedBy;

  Driver copyWith({
    String? fullName,
    String? phoneNumber,
    String? whatsappPhone,
    String? licenseNumber,
    String? notes,
    DriverStatus? status,
    bool? isDeleted,
    int? version,
  }) {
    return Driver(
      id: id,
      eventId: eventId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
      createdBy: createdBy,
      updatedBy: updatedBy,
    );
  }
}
