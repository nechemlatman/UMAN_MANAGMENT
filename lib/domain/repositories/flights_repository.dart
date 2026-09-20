import 'package:uman_event_manager/domain/entities/flight.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';

abstract class FlightsRepository {
  String get eventId;
  Stream<RepositorySignal> get signals;

  Future<List<Flight>> listFlights(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  });

  Future<Flight> readFlight(String eventId, String flightId);

  Future<String> saveFlight({
    required String eventId,
    required String? flightId,
    required int? expectedVersion,
    required FlightInput fields,
    required String requestId,
  });

  Future<void> setFlightDeleted({
    required String eventId,
    required String flightId,
    required int expectedVersion,
    required bool deleted,
  });

  Future<List<FlightPassenger>> listFlightPassengers(String eventId, String flightId);

  Future<String> saveFlightPassenger({
    required String eventId,
    required String? passengerId,
    required int? expectedVersion,
    required FlightPassengerInput fields,
    required String requestId,
  });

  Future<void> setFlightPassengerDeleted({
    required String eventId,
    required String passengerId,
    required int expectedVersion,
    required bool deleted,
  });

  Future<void> dispose();
}

class FlightInput {
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

  FlightInput({
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
  });

  Map<String, dynamic> toJson() {
    return {
      'direction': direction.name.toUpperCase(),
      'airline': airline,
      'flight_number': flightNumber,
      'departure_airport': departureAirport,
      'arrival_airport': arrivalAirport,
      'scheduled_departure_utc': scheduledDepartureUtc.toIso8601String(),
      'scheduled_arrival_utc': scheduledArrivalUtc.toIso8601String(),
      'actual_departure_utc': actualDepartureUtc?.toIso8601String(),
      'actual_arrival_utc': actualArrivalUtc?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'delay_minutes': delayMinutes,
      'terminal': terminal,
      'gate': gate,
      'notes': notes,
      'is_locked': isLocked,
    };
  }
}

class FlightPassengerInput {
  final String flightId;
  final String personId;
  final String? seatNumber;
  final String? bookingReference;
  final String? notes;
  final FlightPassengerStatus status;

  FlightPassengerInput({
    required this.flightId,
    required this.personId,
    this.seatNumber,
    this.bookingReference,
    this.notes,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'flight_id': flightId,
      'person_id': personId,
      'seat_number': seatNumber,
      'booking_reference': bookingReference,
      'notes': notes,
      'status': status.name.toUpperCase(),
    };
  }
}
