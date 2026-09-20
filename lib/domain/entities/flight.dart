enum FlightDirection { inbound, outbound }

enum FlightStatus {
  scheduled,
  delayed,
  cancelled,
  diverted,
  landed,
  unknown;

  static FlightStatus fromString(String value) {
    return FlightStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => FlightStatus.unknown,
    );
  }

  String get displayName => name.toUpperCase();
}

class Flight {
  final String id;
  final String eventId;
  final FlightDirection direction;
  final String airline;
  final String flightNumber;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime scheduledDepartureUtc;
  final DateTime scheduledArrivalUtc;
  final DateTime? actualDepartureUtc;
  final DateTime? actualArrivalUtc;
  final FlightStatus status;
  final int? delayMinutes;
  final String? terminal;
  final String? gate;
  final String? notes;
  final bool isLocked;
  final bool isDeleted;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String createdBy;
  final String updatedBy;
  final int version;

  const Flight({
    required this.id,
    required this.eventId,
    required this.direction,
    required this.airline,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.scheduledDepartureUtc,
    required this.scheduledArrivalUtc,
    this.actualDepartureUtc,
    this.actualArrivalUtc,
    required this.status,
    this.delayMinutes,
    this.terminal,
    this.gate,
    this.notes,
    required this.isLocked,
    required this.isDeleted,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
    required this.version,
  });
}

enum FlightPassengerStatus {
  confirmed,
  tentative,
  cancelled;

  static FlightPassengerStatus fromString(String value) {
    return FlightPassengerStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => FlightPassengerStatus.tentative,
    );
  }

  String get displayName => name.toUpperCase();
}

class FlightPassenger {
  final String id;
  final String flightId;
  final String personId;
  final String? seatNumber;
  final String? bookingReference;
  final String? notes;
  final FlightPassengerStatus status;
  final int version;
  final String? personFirstName; // Joined data for UI
  final String? personLastName; // Joined data for UI

  const FlightPassenger({
    required this.id,
    required this.flightId,
    required this.personId,
    this.seatNumber,
    this.bookingReference,
    this.notes,
    required this.status,
    required this.version,
    this.personFirstName,
    this.personLastName,
  });

  String get personFullName =>
      '${personFirstName ?? ''} ${personLastName ?? ''}'.trim();
}
