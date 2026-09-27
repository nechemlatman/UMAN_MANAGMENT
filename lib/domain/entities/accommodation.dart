import '../value_objects/civil_date.dart';
import '../value_objects/currency_codes.dart';
import '../value_objects/uuid_v4.dart';

enum AccommodationKind {
  apartment('apartment'),
  room('room'),
  sleepingPlace('sleeping_place'),
  assignment('accommodation_assignment');

  const AccommodationKind(this.code);
  final String code;
}

enum ApartmentStatus { active, unavailable, closed }

enum SleepingPlaceType {
  regularBed('REGULAR_BED'),
  bunkBed('BUNK_BED'),
  sofaBed('SOFA_BED'),
  mattress('MATTRESS'),
  custom('CUSTOM');

  const SleepingPlaceType(this.code);
  final String code;
}

enum AccommodationStatus { active, temporary, cancelled }

sealed class AccommodationInput {
  const AccommodationInput();
  AccommodationKind get kind;
  String get label;
  void validate();
}

void _text(String? value, int max, {bool required = false}) {
  if ((required && (value?.trim().isEmpty ?? true)) ||
      (value?.length ?? 0) > max) {
    throw FormatException(
      'Enter required text and keep it within $max characters.',
    );
  }
}

void _id(String value) {
  if (!UuidV4.isValid(value)) {
    throw const FormatException('Select an available record.');
  }
}

class ApartmentInput extends AccommodationInput {
  const ApartmentInput({
    required this.name,
    required this.address,
    this.hebrewAddress,
    this.floor,
    this.entryCode,
    this.landlordName,
    this.landlordPhone,
    this.notes,
    this.status = ApartmentStatus.active,
    this.totalCost,
    this.costCurrency,
    this.costNotes,
  });
  final String name, address;
  final String? hebrewAddress,
      floor,
      entryCode,
      landlordName,
      landlordPhone,
      notes,
      totalCost,
      costCurrency,
      costNotes;
  final ApartmentStatus status;
  @override
  AccommodationKind get kind => AccommodationKind.apartment;
  @override
  String get label => name;
  @override
  void validate() {
    _text(name, 200, required: true);
    _text(address, 500, required: true);
    _text(hebrewAddress, 500);
    _text(floor, 100);
    _text(entryCode, 100);
    _text(landlordName, 200);
    _text(landlordPhone, 50);
    _text(notes, 10000);
    _text(costNotes, 10000);
    // Decimal text preserves the manager's amount without binary floating-point rounding.
    if (totalCost != null && !RegExp(r'^\d+(\.\d+)?$').hasMatch(totalCost!)) {
      throw const FormatException('Enter a non-negative decimal cost.');
    }
    if (costCurrency != null && !eventCurrencyCodes.contains(costCurrency)) {
      throw const FormatException('Choose an ISO currency code.');
    }
  }
}

class RoomInput extends AccommodationInput {
  const RoomInput({
    required this.apartmentId,
    required this.nameOrNumber,
    this.floor,
    this.description,
    this.notes,
  });
  final String apartmentId, nameOrNumber;
  final String? floor, description, notes;
  @override
  AccommodationKind get kind => AccommodationKind.room;
  @override
  String get label => nameOrNumber;
  @override
  void validate() {
    _id(apartmentId);
    _text(nameOrNumber, 200, required: true);
    _text(floor, 100);
    _text(description, 2000);
    _text(notes, 10000);
  }
}

class SleepingPlaceInput extends AccommodationInput {
  const SleepingPlaceInput({
    required this.roomId,
    required this.label,
    this.type = SleepingPlaceType.regularBed,
    this.customTypeName,
    this.positionNotes,
    this.isActive = true,
  });
  final String roomId;
  @override
  final String label;
  final SleepingPlaceType type;
  final String? customTypeName, positionNotes;
  final bool isActive;
  @override
  AccommodationKind get kind => AccommodationKind.sleepingPlace;
  @override
  void validate() {
    _id(roomId);
    _text(label, 200, required: true);
    _text(customTypeName, 200, required: type == SleepingPlaceType.custom);
    _text(positionNotes, 2000);
  }
}

class AccommodationAssignmentInput extends AccommodationInput {
  const AccommodationAssignmentInput({
    required this.sleepingPlaceId,
    required this.personId,
    required this.startDate,
    required this.endDate,
    this.status = AccommodationStatus.active,
    this.notes,
    this.isLocked = false,
  });
  final String sleepingPlaceId, personId;
  final CivilDate startDate, endDate;
  final AccommodationStatus status;
  final String? notes;
  final bool isLocked;
  @override
  AccommodationKind get kind => AccommodationKind.assignment;
  @override
  String get label => '$startDate → $endDate';
  @override
  void validate() {
    _id(sleepingPlaceId);
    _id(personId);
    _text(notes, 10000, required: isLocked);
    if (endDate.compareTo(startDate) <= 0) {
      throw const FormatException(
        'Checkout must be after check-in. Checkout is exclusive.',
      );
    }
  }

  bool overlaps(AccommodationAssignmentInput other) =>
      sleepingPlaceId == other.sleepingPlaceId &&
      status != AccommodationStatus.cancelled &&
      other.status != AccommodationStatus.cancelled &&
      startDate.compareTo(other.endDate) < 0 &&
      other.startDate.compareTo(endDate) < 0;
}

class AccommodationRecord<T extends AccommodationInput> {
  const AccommodationRecord({
    required this.id,
    required this.eventId,
    required this.input,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.isDeleted = false,
    this.deletedAtUtc,
  });
  final String id, eventId;
  final T input;
  final int version;
  final DateTime createdAtUtc, updatedAtUtc;
  final bool isDeleted;
  final DateTime? deletedAtUtc;
}

typedef Apartment = AccommodationRecord<ApartmentInput>;
typedef Room = AccommodationRecord<RoomInput>;
typedef SleepingPlace = AccommodationRecord<SleepingPlaceInput>;
typedef AccommodationAssignment =
    AccommodationRecord<AccommodationAssignmentInput>;

class AccommodationPerson {
  const AccommodationPerson(this.id, this.label, {this.isDeleted = false});
  final String id, label;
  final bool isDeleted;
}

class AccommodationOverlap {
  const AccommodationOverlap(this.firstId, this.secondId);
  final String firstId, secondId;
  String get ruleCode => 'ACCOMMODATION_OVERLAP';
  bool involves(String id) => firstId == id || secondId == id;
}

class AccommodationSnapshot {
  const AccommodationSnapshot({
    this.apartments = const [],
    this.rooms = const [],
    this.sleepingPlaces = const [],
    this.assignments = const [],
    this.people = const [],
    this.overlaps = const [],
  });
  final List<Apartment> apartments;
  final List<Room> rooms;
  final List<SleepingPlace> sleepingPlaces;
  final List<AccommodationAssignment> assignments;
  final List<AccommodationPerson> people;
  final List<AccommodationOverlap> overlaps;
  bool hasOverlap(String id) => overlaps.any((o) => o.involves(id));
  int occupiedBeds(String apartmentId, CivilDate night) {
    final roomIds = rooms
        .where((r) => r.input.apartmentId == apartmentId && !r.isDeleted)
        .map((r) => r.id)
        .toSet();
    final bedIds = sleepingPlaces
        .where(
          (b) =>
              roomIds.contains(b.input.roomId) &&
              !b.isDeleted &&
              b.input.isActive,
        )
        .map((b) => b.id)
        .toSet();
    return assignments
        .where(
          (a) =>
              !a.isDeleted &&
              a.input.status != AccommodationStatus.cancelled &&
              bedIds.contains(a.input.sleepingPlaceId) &&
              a.input.startDate.compareTo(night) <= 0 &&
              a.input.endDate.compareTo(night) > 0,
        )
        .map((a) => a.input.sleepingPlaceId)
        .toSet()
        .length;
  }
}
