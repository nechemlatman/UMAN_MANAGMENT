import '../../domain/entities/accommodation.dart';
import '../../domain/value_objects/civil_date.dart';

Map<String, Object?> encodeAccommodation(AccommodationInput input) =>
    switch (input) {
      ApartmentInput i => {
        'name': i.name,
        'address': i.address,
        'hebrew_address': i.hebrewAddress,
        'floor': i.floor,
        'entry_code': i.entryCode,
        'landlord_name': i.landlordName,
        'landlord_phone': i.landlordPhone,
        'notes': i.notes,
        'status': i.status.name.toUpperCase(),
        'total_cost': i.totalCost,
        'cost_currency': i.costCurrency,
        'cost_notes': i.costNotes,
      },
      RoomInput i => {
        'apartment_id': i.apartmentId,
        'name_or_number': i.nameOrNumber,
        'floor': i.floor,
        'description': i.description,
        'notes': i.notes,
      },
      SleepingPlaceInput i => {
        'room_id': i.roomId,
        'label': i.label,
        'type': i.type?.code,
        'custom_type_name': i.customTypeName,
        'position_notes': i.positionNotes,
        'is_active': i.isActive,
      },
      AccommodationAssignmentInput i => {
        'sleeping_place_id': i.sleepingPlaceId,
        'person_id': i.personId,
        'start_date': i.startDate?.toString(),
        'end_date': i.endDate?.toString(),
        'status': i.status.name.toUpperCase(),
        'notes': i.notes,
        'is_locked': i.isLocked,
      },
    };

AccommodationRecord<T> _record<T extends AccommodationInput>(Map r, T input) =>
    AccommodationRecord<T>(
      id: r['id'],
      eventId: r['event_id'],
      input: input,
      version: (r['version'] as num).toInt(),
      createdAtUtc: DateTime.parse(r['created_at_utc']).toUtc(),
      updatedAtUtc: DateTime.parse(r['updated_at_utc']).toUtc(),
      isDeleted: r['is_deleted'],
      hasBeenOperational: r['has_been_operational'] ?? true,
      deletedAtUtc: r['deleted_at_utc'] == null
          ? null
          : DateTime.parse(r['deleted_at_utc']).toUtc(),
    );
Apartment decodeApartment(Map r) => _record(
  r,
  ApartmentInput(
    name: r['name'],
    address: r['address'],
    hebrewAddress: r['hebrew_address'],
    floor: r['floor'],
    entryCode: r['entry_code'],
    landlordName: r['landlord_name'],
    landlordPhone: r['landlord_phone'],
    notes: r['notes'],
    status: ApartmentStatus.values.byName(
      (r['status'] as String).toLowerCase(),
    ),
    totalCost: r['total_cost']?.toString(),
    costCurrency: r['cost_currency'],
    costNotes: r['cost_notes'],
  ),
);
Room decodeRoom(Map r) => _record(
  r,
  RoomInput(
    apartmentId: r['apartment_id'],
    nameOrNumber: r['name_or_number'],
    floor: r['floor'],
    description: r['description'],
    notes: r['notes'],
  ),
);
SleepingPlace decodeSleepingPlace(Map r) => _record(
  r,
  SleepingPlaceInput(
    roomId: r['room_id'],
    label: r['label'],
    type: r['type'] == null
        ? null
        : SleepingPlaceType.values.firstWhere((t) => t.code == r['type']),
    customTypeName: r['custom_type_name'],
    positionNotes: r['position_notes'],
    isActive: r['is_active'],
  ),
);
AccommodationAssignment decodeAccommodationAssignment(Map r) => _record(
  r,
  AccommodationAssignmentInput(
    sleepingPlaceId: r['sleeping_place_id'],
    personId: r['person_id'],
    startDate: r['start_date'] == null
        ? null
        : CivilDate.parse(r['start_date']),
    endDate: r['end_date'] == null ? null : CivilDate.parse(r['end_date']),
    status: AccommodationStatus.values.byName(
      (r['status'] as String).toLowerCase(),
    ),
    notes: r['notes'],
    isLocked: r['is_locked'],
  ),
);

AccommodationSnapshot decodeAccommodation(Map data, String eventId) {
  List<T> rows<T>(String key, T Function(Map) decode) => List.unmodifiable(
    (data[key] as List).map((row) {
      if (row['event_id'] != eventId) {
        throw const FormatException('Wrong event scope');
      }
      return decode(row as Map);
    }),
  );
  return AccommodationSnapshot(
    apartments: rows('apartments', decodeApartment),
    rooms: rows('rooms', decodeRoom),
    sleepingPlaces: rows('sleeping_places', decodeSleepingPlace),
    assignments: rows(
      'accommodation_assignments',
      decodeAccommodationAssignment,
    ),
    people: rows(
      'people',
      (r) =>
          AccommodationPerson(r['id'], r['label'], isDeleted: r['is_deleted']),
    ),
    overlaps: List.unmodifiable(
      (data['overlaps'] as List).map((r) {
        if (r['rule_code'] != 'ACCOMMODATION_OVERLAP') {
          throw const FormatException('Unknown advisory');
        }
        return AccommodationOverlap(r['first_id'], r['second_id']);
      }),
    ),
  );
}
