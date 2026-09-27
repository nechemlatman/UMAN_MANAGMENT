import '../entities/accommodation.dart';
import 'event_repository.dart';

abstract interface class AccommodationRepository {
  String get eventId;
  Stream<RepositorySignal> get signals;
  Future<AccommodationSnapshot> read();
  Future<String> save(
    AccommodationInput input, {
    required String requestId,
    AccommodationRecord? base,
  });
  Future<void> setDeleted(AccommodationRecord base, bool deleted);
  Future<void> dispose();
}
