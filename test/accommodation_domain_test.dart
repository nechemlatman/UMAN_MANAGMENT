import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/accommodation.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';
import 'package:uman_event_manager/infrastructure/cloud/accommodation_codec.dart';
import 'support/accommodation_fakes.dart';

void main() {
  test(
    'Draft minimums, null codecs and operational validation are separate',
    () {
      const ApartmentInput(name: 'Name only').validate();
      const RoomInput(nameOrNumber: '101').validate();
      const SleepingPlaceInput().validate();
      const AccommodationAssignmentInput().validate();
      const pending = AccommodationAssignmentInput(
        status: AccommodationStatus.active,
      );
      pending.validateForSave();
      expect(pending.validateForOperation, throwsFormatException);
      expect(
        const SleepingPlaceInput(isActive: true).validate,
        throwsFormatException,
      );
      const SleepingPlaceInput(type: SleepingPlaceType.custom).validate();
      final partial = AccommodationAssignmentInput(
        startDate: CivilDate(2026, 9, 20),
      );
      partial.validate();
      expect(encodeAccommodation(partial)['end_date'], isNull);
      expect(partial.overlaps(assignmentInput()), false);
      expect(
        assignmentInput(
          status: AccommodationStatus.draft,
        ).overlaps(assignmentInput()),
        false,
      );
      final data = <String, Object?>{
        ...encodeAccommodation(partial),
        'id': assignmentId,
        'event_id': accEvent,
        'version': 1,
        'created_at_utc': '2026-09-01T00:00:00Z',
        'updated_at_utc': '2026-09-01T00:00:00Z',
        'is_deleted': false,
        'has_been_operational': false,
      };
      final decoded = decodeAccommodationAssignment(data);
      expect(decoded.hasBeenOperational, false);
      expect(decoded.input.endDate, isNull);
      expect(decoded.input.personId, isNull);
      expect(encodeAccommodation(decoded.input), encodeAccommodation(partial));
    },
  );
  test(
    'Apartment validates required text, ISO currency and exact decimal cost',
    () {
      apartmentInput.validate();
      for (final input in [
        const ApartmentInput(name: ' ', address: 'Street'),
        const ApartmentInput(name: 'Main', address: 'Street', totalCost: '-1'),
        const ApartmentInput(
          name: 'Main',
          address: 'Street',
          costCurrency: 'ZZZ',
        ),
      ]) {
        expect(input.validate, throwsFormatException);
      }
      expect(encodeAccommodation(apartmentInput)['total_cost'], '123.4500');
    },
  );
  test('Room and sleeping place require valid parent identifiers', () {
    expect(
      const RoomInput(apartmentId: 'foreign', nameOrNumber: '101').validate,
      throwsFormatException,
    );
    expect(
      const SleepingPlaceInput(roomId: '', label: 'Bed').validate,
      throwsFormatException,
    );
  });
  test('Custom sleeping place needs meaningful name', () {
    expect(
      const SleepingPlaceInput(
        roomId: roomId,
        label: 'Bed',
        type: SleepingPlaceType.custom,
        isActive: true,
        customTypeName: ' \t ',
      ).validate,
      throwsFormatException,
    );
    const SleepingPlaceInput(
      roomId: roomId,
      label: 'Bed',
      type: SleepingPlaceType.custom,
      customTypeName: 'Extra mattress',
    ).validate();
  });
  test(
    'Assignment rejects zero and negative nights; override requires notes',
    () {
      expect(assignmentInput(end: 20).validate, throwsFormatException);
      expect(assignmentInput(end: 19).validate, throwsFormatException);
      expect(
        assignmentInput(locked: true, notes: ' \n ').validate,
        throwsFormatException,
      );
      assignmentInput(
        locked: true,
        notes: 'Manager accepts exception',
      ).validate();
    },
  );
  test(
    'Half-open dates: same-day turnover, boundaries, containment and symmetry',
    () {
      final a = assignmentInput();
      expect(a.overlaps(assignmentInput(start: 23, end: 25)), false);
      expect(a.overlaps(assignmentInput(start: 18, end: 20)), false);
      expect(a.overlaps(assignmentInput(start: 22, end: 24)), true);
      expect(a.overlaps(assignmentInput(start: 21, end: 22)), true);
      expect(assignmentInput(start: 21, end: 22).overlaps(a), true);
    },
  );
  test(
    'Cancellation and different bed excluded; temporary and lock still warn',
    () {
      final a = assignmentInput();
      expect(
        a.overlaps(assignmentInput(status: AccommodationStatus.cancelled)),
        false,
      );
      expect(a.overlaps(assignmentInput(bed: roomId)), false);
      expect(
        a.overlaps(
          assignmentInput(
            status: AccommodationStatus.temporary,
            locked: true,
            notes: 'Override',
          ),
        ),
        true,
      );
    },
  );
  test(
    'Occupancy is dated, bed-distinct, excludes cancelled and deleted assignments',
    () {
      final data = accSnapshot();
      expect(data.occupiedBeds(aptId, CivilDate(2026, 9, 20)), 1);
      expect(data.occupiedBeds(aptId, CivilDate(2026, 9, 23)), 0);
      final altered = AccommodationSnapshot(
        rooms: data.rooms,
        sleepingPlaces: data.sleepingPlaces,
        assignments: [
          accRecord(assignmentId, assignmentInput(), deleted: true),
          accRecord(
            personId,
            assignmentInput(status: AccommodationStatus.cancelled),
          ),
        ],
      );
      expect(altered.occupiedBeds(aptId, CivilDate(2026, 9, 21)), 0);
    },
  );
  test('All four codecs retain optional fields, CivilDate and metadata', () {
    final inputs = <AccommodationInput>[
      const ApartmentInput(
        name: 'Main',
        address: '24',
        hebrewAddress: 'רחוב',
        floor: '2',
        entryCode: '12#',
        landlordName: 'Landlord',
        landlordPhone: '+123',
        notes: 'Note',
        status: ApartmentStatus.unavailable,
        totalCost: '999999999999999999.123456',
        costCurrency: 'ILS',
        costNotes: 'Exact',
      ),
      const RoomInput(
        apartmentId: aptId,
        nameOrNumber: '101',
        floor: '2',
        description: 'Description',
        notes: 'Note',
      ),
      const SleepingPlaceInput(
        roomId: roomId,
        label: 'Extra',
        type: SleepingPlaceType.custom,
        customTypeName: 'Mat',
        positionNotes: 'Window',
        isActive: false,
      ),
      assignmentInput(
        locked: true,
        notes: 'Override',
        status: AccommodationStatus.temporary,
      ),
    ];
    final decoders = [
      decodeApartment,
      decodeRoom,
      decodeSleepingPlace,
      decodeAccommodationAssignment,
    ];
    for (var i = 0; i < inputs.length; i++) {
      final encoded = encodeAccommodation(inputs[i]);
      final row = decoders[i]({
        ...encoded,
        'id': aptId,
        'event_id': accEvent,
        'version': 4,
        'created_at_utc': '2026-09-01T00:00:00Z',
        'updated_at_utc': '2026-09-02T00:00:00Z',
        'is_deleted': true,
        'deleted_at_utc': '2026-09-02T00:00:00Z',
      });
      expect(encodeAccommodation(row.input), encoded);
      expect(row.version, 4);
      expect(row.isDeleted, true);
      expect(row.updatedAtUtc.isUtc, true);
    }
  });
}
