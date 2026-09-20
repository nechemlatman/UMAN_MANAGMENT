import 'dart:convert';
import '../value_objects/civil_date.dart';

enum PersonField {
  firstName,
  lastName,
  hebrewFirstName,
  hebrewLastName,
  phone,
  whatsappPhone,
  email,
  passportName,
  passportNumber,
  passportExpirationDate,
  dateOfBirth,
  nationality,
  emergencyContactName,
  emergencyContactPhone,
  notes,
}

enum PersonStatus { active, inactive }

/// Explicit source fields only. No persistence or UI dependencies.
class PersonInput {
  PersonInput({
    required Map<PersonField, String?> values,
    this.status = PersonStatus.active,
    Map<String, Object?> customFields = const {},
  }) : values = Map.unmodifiable(values),
       _customJson = jsonEncode(customFields);
  final Map<PersonField, String?> values;
  final PersonStatus status;
  final String _customJson;
  Map<String, Object?> get customFields =>
      Map<String, Object?>.from(jsonDecode(_customJson) as Map);
  String? operator [](PersonField field) => values[field];

  Map<PersonField, String> validate() {
    final errors = <PersonField, String>{};
    for (final field in PersonField.values) {
      final value = this[field];
      if (field == PersonField.firstName &&
          (value == null || value.trim().isEmpty)) {
        errors[field] = 'First name is required.';
      }
      final limit = field == PersonField.notes
          ? 10000
          : field == PersonField.email
          ? 320
          : {
              PersonField.phone,
              PersonField.whatsappPhone,
              PersonField.emergencyContactPhone,
            }.contains(field)
          ? 100
          : 200;
      if (value != null && value.runes.length > limit) {
        errors[field] = 'Use at most $limit characters.';
      }
      if ((field == PersonField.dateOfBirth ||
              field == PersonField.passportExpirationDate) &&
          value != null) {
        try {
          CivilDate.parse(value);
        } catch (_) {
          errors[field] = 'Enter a valid date as YYYY-MM-DD, or leave empty.';
        }
      }
    }
    final email = this[PersonField.email];
    if (email != null &&
        email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors[PersonField.email] = 'Enter a valid email, or leave empty.';
    }
    return errors;
  }

  bool get customFieldsValid => utf8.encode(_customJson).length <= 16384;
}

/// Safe operational projection; protected details are fetched only on demand.
class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.eventId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.hebrewFirstName,
    this.hebrewLastName,
    this.whatsappPhone,
    required this.status,
    required this.version,
    required this.isDeleted,
    required this.updatedAtUtc,
  });
  final String id, eventId, firstName, lastName, phone;
  final String? hebrewFirstName, hebrewLastName, whatsappPhone;
  final PersonStatus status;
  final int version;
  final bool isDeleted;
  final DateTime updatedAtUtc;
  String get displayName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
}

class Person {
  const Person({
    required this.summary,
    required this.input,
    required this.createdAtUtc,
    required this.createdBy,
    required this.updatedBy,
    this.deletedAtUtc,
  });
  final PersonSummary summary;
  final PersonInput input;
  final DateTime createdAtUtc;
  final String createdBy, updatedBy;
  final DateTime? deletedAtUtc;
}
