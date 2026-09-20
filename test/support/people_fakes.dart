import 'dart:async';
import 'package:uman_event_manager/domain/entities/person.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/repositories/people_repository.dart';
import 'package:uman_event_manager/infrastructure/cloud/person_codec.dart';

const peopleEvent = '11111111-1111-4111-8111-111111111111';
Person personFixture({
  int version = 1,
  String name = 'David',
  bool deleted = false,
  String eventId = peopleEvent,
}) => decodePerson({
  'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'event_id': eventId,
  'first_name': name,
  'last_name': 'Cohen',
  'phone': '123',
  'hebrew_first_name': 'דוד',
  'hebrew_last_name': null,
  'whatsapp_phone': null,
  'email': null,
  'passport_name': null,
  'passport_number': null,
  'passport_expiration_date': '2030-02-28',
  'date_of_birth': null,
  'nationality': null,
  'emergency_contact_name': null,
  'emergency_contact_phone': null,
  'notes': null,
  'custom_fields': <String, Object?>{'group': 'test'},
  'status': 'ACTIVE',
  'version': version,
  'is_deleted': deleted,
  'deleted_at_utc': deleted ? '2026-09-20T00:00:00Z' : null,
  'created_at_utc': '2026-09-20T00:00:00Z',
  'updated_at_utc': '2026-09-20T00:00:00Z',
  'created_by': peopleEvent,
  'updated_by': peopleEvent,
});

class FakePeopleRepository implements PeopleRepository {
  @override
  final String eventId;
  FakePeopleRepository({this.eventId = peopleEvent});
  final notifications = StreamController<RepositorySignal>.broadcast();
  List<PersonSummary> rows = [personFixture().summary];
  Person person = personFixture();
  CloudFailureKind? readFailure, writeFailure;
  Completer<List<PersonSummary>>? blockedRead;
  int reads = 0, writes = 0, disposed = 0;
  String? lastQuery, request;
  int? lastOffset;
  PersonInput? lastInput;
  @override
  Stream<RepositorySignal> get signals => notifications.stream;
  @override
  Future<List<PersonSummary>> readPage({
    required String query,
    required bool deleted,
    required int limit,
    required int offset,
  }) async {
    reads++;
    lastQuery = query;
    lastOffset = offset;
    if (readFailure != null) throw CloudFailure(readFailure!);
    if (blockedRead != null) {
      final block = blockedRead!;
      blockedRead = null;
      return block.future;
    }
    return rows.where((r) => r.isDeleted == deleted).toList();
  }

  @override
  Future<Person> read(String id) async => person;
  @override
  Future<List<PersonSummary>> duplicates(
    PersonInput input, {
    String? excludeId,
  }) async => [];
  @override
  Future<String> save(
    PersonInput input, {
    required String requestId,
    Person? base,
  }) async {
    writes++;
    request = requestId;
    lastInput = input;
    if (writeFailure != null) throw CloudFailure(writeFailure!);
    person = personFixture(
      version: person.summary.version + 1,
      name: input[PersonField.firstName]!,
    );
    rows = [person.summary];
    return person.summary.id;
  }

  @override
  Future<void> setDeleted(PersonSummary base, bool deleted) async {
    writes++;
    person = personFixture(version: base.version + 1, deleted: deleted);
    rows = [person.summary];
  }

  @override
  Future<void> dispose() async {
    disposed++;
    await notifications.close();
  }
}
