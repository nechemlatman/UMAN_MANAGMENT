import 'dart:convert';

import '../value_objects/civil_date.dart';
import '../value_objects/uuid_v4.dart';

enum EventLifecycleStage {
  planning('PLANNING'),
  ready('READY'),
  travel('TRAVEL'),
  inUman('IN_UMAN'),
  departure('DEPARTURE'),
  closeout('CLOSEOUT'),
  archived('ARCHIVED');

  const EventLifecycleStage(this.storageValue);
  final String storageValue;
  static EventLifecycleStage fromStorageValue(String value) =>
      values.firstWhere((stage) => stage.storageValue == value);
}

final class Event {
  Event({
    required this.id,
    required this.name,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.baseCurrency,
    required this.lifecycleStage,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.hebrewName,
    this.description,
    this.managerNotes,
    Map<String, Object?> settings = const {},
    this.isDeleted = false,
    this.deletedAtUtc,
    this.version = 1,
    this.lastModifiedByDeviceId,
    this.createdBy,
    this.updatedBy,
  }) : settings = _freezeMap(settings) {
    if (!UuidV4.isValid(id) ||
        name.trim().isEmpty ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(baseCurrency) ||
        version < 1) {
      throw ArgumentError('Invalid Event identity or required metadata');
    }
    if (!createdAtUtc.isUtc ||
        !updatedAtUtc.isUtc ||
        (deletedAtUtc != null && !deletedAtUtc!.isUtc)) {
      throw ArgumentError('Event timestamps must be UTC');
    }
    if (isDeleted != (deletedAtUtc != null)) {
      throw ArgumentError('Event tombstone must match deletion state');
    }
  }

  final String id, name, baseCurrency;
  final String? createdBy, updatedBy;
  final String? hebrewName, description, managerNotes, lastModifiedByDeviceId;
  final int year, version;
  final CivilDate startDate, endDate;
  final EventLifecycleStage lifecycleStage;
  final DateTime createdAtUtc, updatedAtUtc;
  final DateTime? deletedAtUtc;
  final bool isDeleted;
  final Map<String, Object?> settings;

  // A stable value representation; user text is preserved verbatim.
  String get _value => jsonEncode([
    id,
    name,
    hebrewName,
    description,
    year,
    startDate.toString(),
    endDate.toString(),
    baseCurrency,
    lifecycleStage.storageValue,
    managerNotes,
    settings,
    createdAtUtc.toIso8601String(),
    updatedAtUtc.toIso8601String(),
    isDeleted,
    deletedAtUtc?.toIso8601String(),
    version,
    lastModifiedByDeviceId,
    createdBy,
    updatedBy,
  ]);

  @override
  bool operator ==(Object other) => other is Event && _value == other._value;
  @override
  int get hashCode => _value.hashCode;
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) {
  final keys = source.keys.toList()..sort();
  return Map<String, Object?>.unmodifiable({
    for (final key in keys) key: _freezeJson(source[key]),
  });
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double && value.isFinite) return value;
  if (value is List) return List<Object?>.unmodifiable(value.map(_freezeJson));
  if (value is Map<String, Object?>) return _freezeMap(value);
  throw ArgumentError('Settings must contain finite JSON values');
}
