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

enum AccommodationStatus {
  draft,
  active,
  temporary,
  cancelled;

  bool get isOperational => this == active || this == temporary;
}

sealed class AccommodationInput {
  const AccommodationInput();
  AccommodationKind get kind;
  String? get label;
  void validateForSave();
  void validateForOperation() {}
  void validate() {
    validateForSave();
    validateForOperation();
  }
}

void _text(
  String? value,
  int max, {
  bool required = false,
  required String field,
}) {
  if ((required && (value?.trim().isEmpty ?? true)) ||
      (value?.length ?? 0) > max) {
    throw FormatException(
      required && (value?.trim().isEmpty ?? true)
          ? 'Enter $field to identify this record.'
          : '$field must be at most $max characters.',
    );
  }
}

void _id(String? value) {
  if (value != null && !UuidV4.isValid(value)) {
    throw const FormatException('Select an available record.');
  }
}

class ApartmentInput extends AccommodationInput {
  const ApartmentInput({
    required this.name,
    this.address,
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
  final String name;
  final String? address;
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
  void validateForSave() {
    _text(name, 200, required: true, field: 'an apartment name');
    _text(address, 500, field: 'address');
    _text(hebrewAddress, 500, field: 'hebrew address');
    _text(floor, 100, field: 'floor');
    _text(entryCode, 100, field: 'entry code');
    _text(landlordName, 200, field: 'landlord name');
    _text(landlordPhone, 50, field: 'landlord phone');
    _text(notes, 10000, field: 'notes');
    _text(costNotes, 10000, field: 'cost notes');
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
    this.apartmentId,
    required this.nameOrNumber,
    this.floor,
    this.description,
    this.notes,
  });
  final String nameOrNumber;
  final String? apartmentId;
  final String? floor, description, notes;
  @override
  AccommodationKind get kind => AccommodationKind.room;
  @override
  String get label => nameOrNumber;
  @override
  void validateForSave() {
    _id(apartmentId);
    _text(nameOrNumber, 200, required: true, field: 'a room name or number');
    _text(floor, 100, field: 'floor');
    _text(description, 2000, field: 'description');
    _text(notes, 10000, field: 'notes');
  }
}

class SleepingPlaceInput extends AccommodationInput {
  const SleepingPlaceInput({
    this.roomId,
    this.label,
    this.type,
    this.customTypeName,
    this.positionNotes,
    this.isActive = false,
  });
  final String? roomId;
  @override
  final String? label;
  final SleepingPlaceType? type;
  final String? customTypeName, positionNotes;
  final bool isActive;
  @override
  AccommodationKind get kind => AccommodationKind.sleepingPlace;
  @override
  void validateForSave() {
    _id(roomId);
    _text(label, 200, field: 'label');
    _text(customTypeName, 200, field: 'custom type name');
    _text(positionNotes, 2000, field: 'position notes');
  }

  @override
  void validateForOperation() {
    if (!isActive) return;
    if (roomId == null || type == null) {
      throw const FormatException(
        'Choose a room and type before activating this sleeping place.',
      );
    }
    if (type == SleepingPlaceType.custom &&
        (customTypeName?.trim().isEmpty ?? true)) {
      throw const FormatException(
        'Describe the custom type before activating this sleeping place.',
      );
    }
  }
}

class AccommodationAssignmentInput extends AccommodationInput {
  const AccommodationAssignmentInput({
    this.sleepingPlaceId,
    this.personId,
    this.startDate,
    this.endDate,
    this.status = AccommodationStatus.draft,
    this.notes,
    this.isLocked = false,
  });
  final String? sleepingPlaceId, personId;
  final CivilDate? startDate, endDate;
  final AccommodationStatus status;
  final String? notes;
  final bool isLocked;
  @override
  AccommodationKind get kind => AccommodationKind.assignment;
  @override
  String? get label => null;
  @override
  void validateForSave() {
    _id(sleepingPlaceId);
    _id(personId);
    _text(notes, 10000, field: 'notes');
    if (startDate != null &&
        endDate != null &&
        endDate!.compareTo(startDate!) <= 0) {
      throw const FormatException(
        'Checkout must be after check-in. Checkout is exclusive.',
      );
    }
  }

  @override
  void validateForOperation() {
    if (isLocked && (notes?.trim().isEmpty ?? true)) {
      throw const FormatException(
        'Explain the capacity override in Notes before applying it.',
      );
    }
    if (status.isOperational &&
        (sleepingPlaceId == null ||
            personId == null ||
            startDate == null ||
            endDate == null)) {
      throw const FormatException(
        'Choose a person, sleeping place, check-in and checkout before making this assignment active or temporary. You can save it as a draft.',
      );
    }
  }

  bool overlaps(AccommodationAssignmentInput other) =>
      sleepingPlaceId != null &&
      sleepingPlaceId == other.sleepingPlaceId &&
      status.isOperational &&
      other.status.isOperational &&
      startDate != null &&
      endDate != null &&
      other.startDate != null &&
      other.endDate != null &&
      startDate!.compareTo(other.endDate!) < 0 &&
      other.startDate!.compareTo(endDate!) < 0;
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
    this.hasBeenOperational = true,
  });
  final String id, eventId;
  final T input;
  final int version;
  final DateTime createdAtUtc, updatedAtUtc;
  final bool isDeleted;
  final bool hasBeenOperational;
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
              a.input.status.isOperational &&
              bedIds.contains(a.input.sleepingPlaceId) &&
              a.input.startDate != null &&
              a.input.endDate != null &&
              a.input.startDate!.compareTo(night) <= 0 &&
              a.input.endDate!.compareTo(night) > 0,
        )
        .map((a) => a.input.sleepingPlaceId)
        .toSet()
        .length;
  }
}
