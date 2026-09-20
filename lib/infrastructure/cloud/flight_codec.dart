import '../../domain/entities/flight.dart';

Flight decodeFlight(Map<String, dynamic> json) {
  return Flight(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    direction: FlightDirection.values.firstWhere(
      (e) => e.name.toUpperCase() == (json['direction'] as String).toUpperCase(),
    ),
    airline: json['airline'] as String,
    flightNumber: json['flight_number'] as String,
    departureAirport: json['departure_airport'] as String,
    arrivalAirport: json['arrival_airport'] as String,
    scheduledDepartureUtc: DateTime.parse(json['scheduled_departure_utc'] as String),
    scheduledArrivalUtc: DateTime.parse(json['scheduled_arrival_utc'] as String),
    actualDepartureUtc: json['actual_departure_utc'] != null
        ? DateTime.parse(json['actual_departure_utc'] as String)
        : null,
    actualArrivalUtc: json['actual_arrival_utc'] != null
        ? DateTime.parse(json['actual_arrival_utc'] as String)
        : null,
    status: FlightStatus.fromString(json['status'] as String),
    delayMinutes: json['delay_minutes'] as int?,
    terminal: json['terminal'] as String?,
    gate: json['gate'] as String?,
    notes: json['notes'] as String?,
    isLocked: json['is_locked'] as bool,
    isDeleted: json['is_deleted'] as bool,
    createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
    updatedAtUtc: DateTime.parse(json['updated_at_utc'] as String),
    createdBy: json['created_by'] as String,
    updatedBy: json['updated_by'] as String,
    version: json['version'] as int,
  );
}

FlightPassenger decodeFlightPassenger(Map<String, dynamic> json) {
  return FlightPassenger(
    id: json['id'] as String,
    flightId: json['flight_id'] as String,
    personId: json['person_id'] as String,
    seatNumber: json['seat_number'] as String?,
    bookingReference: json['booking_reference'] as String?,
    notes: json['notes'] as String?,
    status: FlightPassengerStatus.fromString(json['status'] as String),
    version: json['version'] as int,
    personFirstName: json['person_first_name'] as String?,
    personLastName: json['person_last_name'] as String?,
  );
}
