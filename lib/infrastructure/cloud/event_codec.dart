import '../../domain/entities/event.dart';
import '../../domain/value_objects/civil_date.dart';

Event decodeEvent(Map<String, dynamic> row) => Event(
  id: row['id'] as String,
  name: row['name'] as String,
  year: row['year'] as int,
  startDate: CivilDate.parse(row['start_date'] as String),
  endDate: CivilDate.parse(row['end_date'] as String),
  baseCurrency: row['base_currency'] as String,
  lifecycleStage: EventLifecycleStage.fromStorageValue(
    row['lifecycle_stage'] as String,
  ),
  createdAtUtc: DateTime.parse(row['created_at_utc'] as String).toUtc(),
  updatedAtUtc: DateTime.parse(row['updated_at_utc'] as String).toUtc(),
  createdBy: row['created_by'] as String,
  updatedBy: row['updated_by'] as String,
  version: row['version'] as int,
  hebrewName: row['hebrew_name'] as String?,
  description: row['description'] as String?,
  managerNotes: row['manager_notes'] as String?,
  settings: Map<String, Object?>.from(row['settings'] as Map),
  isDeleted: row['is_deleted'] as bool,
  deletedAtUtc: row['deleted_at_utc'] == null
      ? null
      : DateTime.parse(row['deleted_at_utc'] as String).toUtc(),
);
Map<String, Object?> encodeEvent(Event e) => {
  'id': e.id,
  'name': e.name,
  'year': e.year,
  'start_date': e.startDate.toString(),
  'end_date': e.endDate.toString(),
  'base_currency': e.baseCurrency,
  'lifecycle_stage': e.lifecycleStage.storageValue,
  'created_at_utc': e.createdAtUtc.toIso8601String(),
  'updated_at_utc': e.updatedAtUtc.toIso8601String(),
  'created_by': e.createdBy,
  'updated_by': e.updatedBy,
  'version': e.version,
  'hebrew_name': e.hebrewName,
  'description': e.description,
  'manager_notes': e.managerNotes,
  'settings': e.settings,
  'is_deleted': e.isDeleted,
  'deleted_at_utc': e.deletedAtUtc?.toIso8601String(),
};
