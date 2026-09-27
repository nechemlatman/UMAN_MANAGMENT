import 'dart:async';
import 'package:uman_event_manager/domain/entities/trip.dart';
import 'package:uman_event_manager/domain/repositories/trips_repository.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';

const tripEvent = '11111111-1111-4111-8111-111111111111';
const tripId = '33333333-3333-4333-8333-333333333333';
TripInput tripInput({
  DateTime? arrival,
  DateTime? actual,
  TripStatus status = TripStatus.planned,
}) => TripInput(
  direction: TripDirection.inbound,
  origin: 'שדה Airport',
  destination: 'Uman',
  scheduledDepartureUtc: DateTime.utc(2026, 9, 1, 10),
  scheduledArrivalUtc: arrival ?? DateTime.utc(2026, 9, 1, 12),
  actualArrivalUtc: actual,
  status: status,
);
Trip tripSample({
  int version = 1,
  int count = 1,
  int capacity = 1,
  bool deleted = false,
  bool review = false,
  TripInput? input,
}) => Trip(
  id: tripId,
  eventId: tripEvent,
  input: input ?? tripInput(),
  version: version,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  createdBy: tripEvent,
  updatedBy: tripEvent,
  isDeleted: deleted,
  activePassengers: count,
  vehicleCapacity: capacity,
  flightNeedsReview: review,
);

class FakeTripsRepository implements TripsRepository {
  @override
  String get eventId => tripEvent;
  final changes = StreamController<RepositorySignal>.broadcast();
  @override
  Stream<RepositorySignal> get signals => changes.stream;
  List<Trip> rows = [tripSample()];
  List<TripPassenger> passengers = [];
  CloudFailureKind? readFailure, writeFailure;
  Completer<void>? gate;
  int reads = 0, writes = 0;
  bool disposed = false;
  @override
  Future<List<Trip>> listTrips({
    String query = '',
    bool deleted = false,
  }) async {
    reads++;
    await gate?.future;
    if (readFailure != null) throw CloudFailure(readFailure!);
    return rows
        .where((t) => t.isDeleted == deleted && t.input.origin.contains(query))
        .toList();
  }

  @override
  Future<Trip?> readTrip(String id) async =>
      rows.where((t) => t.id == id).firstOrNull;
  @override
  Future<List<TripPassenger>> listPassengers(
    String tripId, {
    bool deleted = false,
  }) async => passengers.where((p) => p.isDeleted == deleted).toList();
  @override
  Future<Map<String, List<TripAssignmentOption>>> assignmentOptions() async => {
    'drivers': [],
    'vehicles': [],
    'flights': [],
    'people': [const TripAssignmentOption(tripEvent, 'Test Person')],
  };
  @override
  Future<String> saveTrip(
    TripInput input, {
    required String requestId,
    Trip? base,
  }) async {
    writes++;
    if (writeFailure != null) throw CloudFailure(writeFailure!);
    input.validate();
    rows = [tripSample(input: input, version: (base?.version ?? 0) + 1)];
    return tripId;
  }

  @override
  Future<String> savePassenger(
    TripPassengerInput input, {
    required String requestId,
    TripPassenger? base,
  }) async {
    writes++;
    if (writeFailure != null) throw CloudFailure(writeFailure!);
    input.validate();
    return tripId;
  }

  @override
  Future<void> setTripDeleted(Trip base, bool deleted) async {
    rows = [tripSample(deleted: deleted, version: base.version + 1)];
  }

  @override
  Future<void> setPassengerDeleted(TripPassenger base, bool deleted) async {}
  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await changes.close();
  }
}
