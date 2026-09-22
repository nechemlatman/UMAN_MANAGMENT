enum VehicleType {
  car('CAR', 'Car'),
  van('VAN', 'Van'),
  minibus('MINIBUS', 'Minibus'),
  bus('BUS', 'Bus'),
  custom('CUSTOM', 'Custom');

  const VehicleType(this.code, this.displayName);
  final String code;
  final String displayName;

  static VehicleType fromCode(String code) {
    return VehicleType.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => VehicleType.van,
    );
  }
}

enum VehicleStatus {
  available('AVAILABLE', 'Available'),
  maintenance('MAINTENANCE', 'In Maintenance'),
  unavailable('UNAVAILABLE', 'Unavailable');

  const VehicleStatus(this.code, this.displayName);
  final String code;
  final String displayName;

  static VehicleStatus fromCode(String code) {
    return VehicleStatus.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => VehicleStatus.available,
    );
  }
}

class VehicleInput {
  const VehicleInput({
    required this.name,
    this.type = VehicleType.van,
    this.licensePlate = '',
    this.capacity = 1,
    this.status = VehicleStatus.available,
    this.notes = '',
  });

  final String name;
  final VehicleType type;
  final String licensePlate;
  final int capacity;
  final VehicleStatus status;
  final String notes;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'vehicle_type': type.code,
      'license_plate': licensePlate,
      'capacity': capacity,
      'status': status.code,
      'notes': notes,
    };
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.eventId,
    required this.name,
    required this.type,
    required this.licensePlate,
    required this.capacity,
    required this.status,
    required this.notes,
    required this.isDeleted,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String eventId;
  final String name;
  final VehicleType type;
  final String licensePlate;
  final int capacity;
  final VehicleStatus status;
  final String notes;
  final bool isDeleted;
  final int version;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String createdBy;
  final String updatedBy;

  Vehicle copyWith({
    String? name,
    VehicleType? type,
    String? licensePlate,
    int? capacity,
    VehicleStatus? status,
    String? notes,
    bool? isDeleted,
    int? version,
  }) {
    return Vehicle(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      type: type ?? this.type,
      licensePlate: licensePlate ?? this.licensePlate,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
      createdBy: createdBy,
      updatedBy: updatedBy,
    );
  }
}
