import '../value_objects/form_policy.dart';
import '../value_objects/uuid_v4.dart';

enum TripDirection { inbound, outbound, local }

enum TripStatus {
  planned('PLANNED'),
  confirmed('CONFIRMED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TripStatus(this.code);
  final String code;
  bool get requiresComplete =>
      this == confirmed || this == inProgress || this == completed;
}

enum TripPassengerStatus {
  assigned('ASSIGNED'),
  confirmed('CONFIRMED'),
  pickedUp('PICKED_UP'),
  droppedOff('DROPPED_OFF'),
  noShow('NO_SHOW'),
  cancelled('CANCELLED');

  const TripPassengerStatus(this.code);
  final String code;
}

class TripInput {
  const TripInput({
    required this.direction,
    this.origin,
    this.destination,
    this.scheduledDepartureUtc,
    this.scheduledArrivalUtc,
    this.actualDepartureUtc,
    this.actualArrivalUtc,
    this.driverId,
    this.vehicleId,
    this.relatedFlightId,
    this.status = TripStatus.planned,
    this.notes,
    this.isLocked = false,
  });
  final TripDirection direction;
  final String? origin, destination;
  final DateTime? scheduledDepartureUtc, scheduledArrivalUtc;
  final DateTime? actualDepartureUtc, actualArrivalUtc;
  final String? driverId, vehicleId, relatedFlightId, notes;
  final TripStatus status;
  final bool isLocked;
  void validateForSave() {
    for (final id in [driverId, vehicleId, relatedFlightId]) {
      if (id != null && !UuidV4.isValid(id)) {
        throw const FormatException('Invalid assignment identifier.');
      }
    }
    if (origin != null && origin!.trim().isEmpty ||
        destination != null && destination!.trim().isEmpty) {
      throw const FormatException(
        'Enter a location, or clear the field if it is unknown.',
      );
    }
    FormPolicy.text(origin, 500, 'Origin');
    FormPolicy.text(destination, 500, 'Destination');
    FormPolicy.text(notes, 10000, 'Notes');
    FormPolicy.schedule(
      scheduledDepartureUtc,
      scheduledArrivalUtc,
      actualDeparture: actualDepartureUtc,
      actualArrival: actualArrivalUtc,
    );
  }

  void validateForOperation() {
    if (status.requiresComplete) {
      FormPolicy.routeOperation(
        origin,
        destination,
        scheduledDepartureUtc,
        scheduledArrivalUtc,
      );
    }
  }

  void validate() {
    validateForSave();
    validateForOperation();
  }
}

class TripPassengerInput {
  const TripPassengerInput({
    required this.tripId,
    required this.personId,
    this.pickupLocation,
    this.pickupNotes,
    this.status = TripPassengerStatus.assigned,
    this.notes,
  });
  final String tripId, personId;
  final String? pickupLocation, pickupNotes, notes;
  final TripPassengerStatus status;
  void validate() {
    if (!UuidV4.isValid(tripId) ||
        !UuidV4.isValid(personId) ||
        (pickupLocation?.length ?? 0) > 500 ||
        (pickupNotes?.length ?? 0) > 2000 ||
        (notes?.length ?? 0) > 10000) {
      throw const FormatException(
        'Select a trip and person; shorten the pickup details or notes.',
      );
    }
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.eventId,
    required this.input,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
    this.isDeleted = false,
    this.deletedAtUtc,
    this.activePassengers = 0,
    this.vehicleCapacity,
    this.flightNeedsReview = false,
  });
  final String id, eventId, createdBy, updatedBy;
  final TripInput input;
  final int version, activePassengers;
  final int? vehicleCapacity;
  final DateTime createdAtUtc, updatedAtUtc;
  final DateTime? deletedAtUtc;
  final bool isDeleted, flightNeedsReview;
  bool get overCapacity =>
      vehicleCapacity != null && activePassengers > vehicleCapacity!;
}

class TripPassenger {
  const TripPassenger({
    required this.id,
    required this.eventId,
    required this.input,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
    this.isDeleted = false,
    this.deletedAtUtc,
  });
  final String id, eventId, createdBy, updatedBy;
  final TripPassengerInput input;
  final int version;
  final DateTime createdAtUtc, updatedAtUtc;
  final DateTime? deletedAtUtc;
  final bool isDeleted;
  bool get active =>
      !isDeleted && input.status != TripPassengerStatus.cancelled;
}

class TripAssignmentOption {
  const TripAssignmentOption(this.id, this.label);
  final String id, label;
}
