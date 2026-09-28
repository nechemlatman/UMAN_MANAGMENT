import 'dart:async';
import 'package:uman_event_manager/domain/entities/accommodation.dart';
import 'package:uman_event_manager/domain/repositories/accommodation_repository.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';

const accEvent = '11111111-1111-4111-8111-111111111111';
const aptId = '22222222-2222-4222-8222-222222222222';
const roomId = '33333333-3333-4333-8333-333333333333';
const bedId = '44444444-4444-4444-8444-444444444444';
const personId = '55555555-5555-4555-8555-555555555555';
const assignmentId = '66666666-6666-4666-8666-666666666666';
AccommodationRecord<T> accRecord<T extends AccommodationInput>(
  String id,
  T input, {
  int version = 1,
  bool deleted = false,
  String eventId = accEvent,
}) => AccommodationRecord(
  id: id,
  eventId: eventId,
  input: input,
  version: version,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  isDeleted: deleted,
  deletedAtUtc: deleted ? DateTime.utc(2026) : null,
);
const apartmentInput = ApartmentInput(
  name: 'דירה Main',
  address: 'Street 24',
  totalCost: '123.4500',
  costCurrency: 'USD',
);
AccommodationAssignmentInput assignmentInput({
  int start = 20,
  int end = 23,
  String bed = bedId,
  AccommodationStatus status = AccommodationStatus.active,
  bool locked = false,
  String? notes,
}) => AccommodationAssignmentInput(
  sleepingPlaceId: bed,
  personId: personId,
  startDate: CivilDate(2026, 9, start),
  endDate: CivilDate(2026, 9, end),
  status: status,
  isLocked: locked,
  notes: notes,
);
AccommodationSnapshot accSnapshot({
  int version = 1,
  bool deleted = false,
  List<AccommodationOverlap> overlaps = const [],
}) => AccommodationSnapshot(
  apartments: [
    accRecord(aptId, apartmentInput, version: version, deleted: deleted),
  ],
  rooms: [
    accRecord(
      roomId,
      const RoomInput(apartmentId: aptId, nameOrNumber: 'Room א'),
    ),
  ],
  sleepingPlaces: [
    accRecord(
      bedId,
      const SleepingPlaceInput(
        roomId: roomId,
        label: 'Bed A',
        type: SleepingPlaceType.regularBed,
        isActive: true,
      ),
    ),
  ],
  assignments: [accRecord(assignmentId, assignmentInput())],
  people: [const AccommodationPerson(personId, 'אדם Person')],
  overlaps: overlaps,
);

class FakeAccommodationRepository implements AccommodationRepository {
  @override
  String get eventId => accEvent;
  final changes = StreamController<RepositorySignal>.broadcast();
  @override
  Stream<RepositorySignal> get signals => changes.stream;
  AccommodationSnapshot data = accSnapshot();
  CloudFailureKind? readFailure, writeFailure;
  Completer<void>? gate, writeGate;
  int reads = 0, writes = 0, activeReads = 0, maxActiveReads = 0;
  bool disposed = false;
  AccommodationInput? saved;
  String? request;
  AccommodationRecord? base;
  @override
  Future<AccommodationSnapshot> read() async {
    reads++;
    activeReads++;
    if (activeReads > maxActiveReads) maxActiveReads = activeReads;
    try {
      await gate?.future;
      if (readFailure != null) throw CloudFailure(readFailure!);
      return data;
    } finally {
      activeReads--;
    }
  }

  @override
  Future<String> save(
    AccommodationInput input, {
    required String requestId,
    AccommodationRecord? base,
  }) async {
    writes++;
    saved = input;
    request = requestId;
    this.base = base;
    await writeGate?.future;
    if (writeFailure != null) throw CloudFailure(writeFailure!);
    input.validate();
    return aptId;
  }

  @override
  Future<void> setDeleted(AccommodationRecord base, bool deleted) async {
    data = accSnapshot(version: base.version + 1, deleted: deleted);
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await changes.close();
  }
}
