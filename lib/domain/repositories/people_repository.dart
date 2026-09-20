import '../entities/person.dart';
import 'event_repository.dart';

abstract interface class PeopleRepository {
  String get eventId;
  Stream<RepositorySignal> get signals;
  Future<List<PersonSummary>> readPage({
    required String query,
    required bool deleted,
    required int limit,
    required int offset,
  });
  Future<Person> read(String id);
  Future<List<PersonSummary>> duplicates(
    PersonInput input, {
    String? excludeId,
  });
  Future<String> save(
    PersonInput input, {
    required String requestId,
    Person? base,
  });
  Future<void> setDeleted(PersonSummary base, bool deleted);
  Future<void> dispose();
}
