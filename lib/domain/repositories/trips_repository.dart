import '../entities/trip.dart';
import 'event_repository.dart';

abstract class TripsRepository {
  String get eventId;
  Stream<RepositorySignal> get signals;
  Future<List<Trip>> listTrips({String query = '', bool deleted = false});
  Future<Trip?> readTrip(String id);
  Future<List<TripPassenger>> listPassengers(
    String tripId, {
    bool deleted = false,
  });
  Future<Map<String, List<TripAssignmentOption>>> assignmentOptions();
  Future<String> saveTrip(
    TripInput input, {
    required String requestId,
    Trip? base,
  });
  Future<String> savePassenger(
    TripPassengerInput input, {
    required String requestId,
    TripPassenger? base,
  });
  Future<void> setTripDeleted(Trip base, bool deleted);
  Future<void> setPassengerDeleted(TripPassenger base, bool deleted);
  Future<void> dispose();
}
