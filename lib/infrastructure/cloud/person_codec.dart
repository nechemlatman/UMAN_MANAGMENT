import '../../domain/entities/person.dart';

String personFieldKey(PersonField field) => field.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '_${m[0]!.toLowerCase()}',
);

Map<String, Object?> encodePersonInput(PersonInput input) => {
  for (final field in PersonField.values)
    personFieldKey(field):
        input[field] ??
        (field == PersonField.lastName || field == PersonField.phone
            ? ''
            : null),
  'status': input.status.name.toUpperCase(),
  'custom_fields': input.customFields,
};

PersonSummary decodePersonSummary(Map<String, dynamic> row) => PersonSummary(
  id: row['id'] as String,
  eventId: row['event_id'] as String,
  firstName: row['first_name'] as String,
  lastName: row['last_name'] as String,
  phone: row['phone'] as String,
  hebrewFirstName: row['hebrew_first_name'] as String?,
  hebrewLastName: row['hebrew_last_name'] as String?,
  whatsappPhone: row['whatsapp_phone'] as String?,
  status: PersonStatus.values.byName((row['status'] as String).toLowerCase()),
  version: (row['version'] as num).toInt(),
  isDeleted: row['is_deleted'] as bool,
  updatedAtUtc: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
);

Person decodePerson(Map<String, dynamic> row) => Person(
  summary: decodePersonSummary(row),
  input: PersonInput(
    values: {
      for (final field in PersonField.values)
        field: row[personFieldKey(field)] as String?,
    },
    status: PersonStatus.values.byName((row['status'] as String).toLowerCase()),
    customFields: Map<String, Object?>.from(row['custom_fields'] as Map),
  ),
  createdAtUtc: DateTime.parse(row['created_at_utc'] as String).toUtc(),
  createdBy: row['created_by'] as String,
  updatedBy: row['updated_by'] as String,
  deletedAtUtc: row['deleted_at_utc'] == null
      ? null
      : DateTime.parse(row['deleted_at_utc'] as String).toUtc(),
);
