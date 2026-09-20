import 'dart:async';
import 'package:uman_event_manager/domain/entities/flight.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/repositories/flights_repository.dart';
import 'package:uman_event_manager/infrastructure/cloud/flight_codec.dart';

const flightsEvent = '11111111-1111-4111-8111-111111111111';

Flight flightFixture({
  int version = 1,
  String airline = 'El Al',
  bool deleted = false,
  String eventId = flightsEvent,
}) =>
    decodeFlight({
      'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'event_id': eventId,
      'direction': 'INBOUND',
      'airline': airline,
      'flight_number': 'LY001',
      'departure_airport': 'JFK',
      'arrival_airport': 'TLV',
      'scheduled_departure_utc': '2026-09-21T10:00:00Z',
      'scheduled_arrival_utc': '2026-09-21T20:00:00Z',
      'actual_departure_utc': null,
      'actual_arrival_utc': null,
      'status': 'SCHEDULED',
      'delay_minutes': null,
      'terminal': '4',
      'gate': 'B20',
      'notes': 'Test flight',
      'is_locked': false,
      'is_deleted': deleted,
      'deleted_at_utc': deleted ? '2026-09-20T00:00:00Z' : null,
      'created_at_utc': '2026-09-20T00:00:00Z',
      'updated_at_utc': '2026-09-20T00:00:00Z',
      'created_by': flightsEvent,
      'updated_by': flightsEvent,
      'version': version,
    });

class FakeFlightsRepository implements FlightsRepository {
  @override
  final String eventId;
  FakeFlightsRepository({this.eventId = flightsEvent});
  final notifications = StreamController<RepositorySignal>.broadcast();
  List<Flight> flights = [flightFixture()];
  List<FlightPassenger> passengers = [];
  int reads = 0, writes = 0, disposed = 0;
  CloudFailureKind? failure;

  @override
  Stream<RepositorySignal> get signals => notifications.stream;

  @override
  Future<List<Flight>> listFlights(String eventId,
      {bool includeDeleted = false}) async {
    reads++;
    if (failure != null) throw CloudFailure(failure!);
    return flights.where((f) => f.isDeleted == includeDeleted).toList();
  }

  @override
  Future<Flight> readFlight(String eventId, String flightId) async {
    reads++;
    return flights.firstWhere((f) => f.id == flightId);
  }

  @override
  Future<String> saveFlight({
    required String eventId,
    required String? flightId,
    required int? expectedVersion,
    required FlightInput fields,
    required String requestId,
  }) async {
    writes++;
    if (failure != null) throw CloudFailure(failure!);
    return 'new-flight-id';
  }

  @override
  Future<void> setFlightDeleted({
    required String eventId,
    required String flightId,
    required int expectedVersion,
    required bool deleted,
  }) async {
    writes++;
  }

  @override
  Future<List<FlightPassenger>> listFlightPassengers(
      String eventId, String flightId) async {
    reads++;
    return passengers;
  }

  @override
  Future<String> saveFlightPassenger({
    required String eventId,
    required String? passengerId,
    required int? expectedVersion,
    required FlightPassengerInput fields,
    required String requestId,
  }) async {
    writes++;
    return 'new-passenger-id';
  }

  @override
  Future<void> setFlightPassengerDeleted({
    required String eventId,
    required String passengerId,
    required int expectedVersion,
    required bool deleted,
  }) async {
    writes++;
  }

  @override
  Future<void> dispose() async {
    disposed++;
    await notifications.close();
  }
}
