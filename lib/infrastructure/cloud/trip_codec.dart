import '../../domain/entities/trip.dart';

Map<String, Object?> encodeTrip(TripInput t) => {
  'direction': t.direction.name.toUpperCase(),
  'origin': t.origin,
  'destination': t.destination,
  'scheduled_departure_utc': t.scheduledDepartureUtc.toIso8601String(),
  'scheduled_arrival_utc': t.scheduledArrivalUtc.toIso8601String(),
  'actual_departure_utc': t.actualDepartureUtc?.toIso8601String(),
  'actual_arrival_utc': t.actualArrivalUtc?.toIso8601String(),
  'driver_id': t.driverId,
  'vehicle_id': t.vehicleId,
  'related_flight_id': t.relatedFlightId,
  'status': t.status.code,
  'notes': t.notes,
  'is_locked': t.isLocked,
};
Map<String, Object?> encodeTripPassenger(TripPassengerInput p) => {
  'trip_id': p.tripId,
  'person_id': p.personId,
  'pickup_location': p.pickupLocation,
  'pickup_notes': p.pickupNotes,
  'passenger_status': p.status.code,
  'notes': p.notes,
};
DateTime _date(dynamic value) => DateTime.parse(value as String).toUtc();
DateTime? _optional(dynamic value) => value == null ? null : _date(value);
Trip decodeTrip(Map<String, dynamic> j) => Trip(
  id: j['id'],
  eventId: j['event_id'],
  version: (j['version'] as num).toInt(),
  createdBy: j['created_by'],
  updatedBy: j['updated_by'],
  createdAtUtc: _date(j['created_at_utc']),
  updatedAtUtc: _date(j['updated_at_utc']),
  deletedAtUtc: _optional(j['deleted_at_utc']),
  isDeleted: j['is_deleted'],
  activePassengers: (j['active_passengers'] as num? ?? 0).toInt(),
  vehicleCapacity: (j['vehicle_capacity'] as num?)?.toInt(),
  flightNeedsReview: j['flight_needs_review'] ?? false,
  input: TripInput(
    direction: TripDirection.values.byName(
      (j['direction'] as String).toLowerCase(),
    ),
    origin: j['origin'],
    destination: j['destination'],
    scheduledDepartureUtc: _date(j['scheduled_departure_utc']),
    scheduledArrivalUtc: _date(j['scheduled_arrival_utc']),
    actualDepartureUtc: _optional(j['actual_departure_utc']),
    actualArrivalUtc: _optional(j['actual_arrival_utc']),
    driverId: j['driver_id'],
    vehicleId: j['vehicle_id'],
    relatedFlightId: j['related_flight_id'],
    notes: j['notes'],
    isLocked: j['is_locked'],
    status: TripStatus.values.firstWhere((v) => v.code == j['status']),
  ),
);
TripPassenger decodeTripPassenger(Map<String, dynamic> j) => TripPassenger(
  id: j['id'],
  eventId: j['event_id'],
  version: (j['version'] as num).toInt(),
  createdBy: j['created_by'],
  updatedBy: j['updated_by'],
  createdAtUtc: _date(j['created_at_utc']),
  updatedAtUtc: _date(j['updated_at_utc']),
  deletedAtUtc: _optional(j['deleted_at_utc']),
  isDeleted: j['is_deleted'],
  input: TripPassengerInput(
    tripId: j['trip_id'],
    personId: j['person_id'],
    pickupLocation: j['pickup_location'],
    pickupNotes: j['pickup_notes'],
    notes: j['notes'],
    status: TripPassengerStatus.values.firstWhere(
      (v) => v.code == j['passenger_status'],
    ),
  ),
);
