import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:uman_event_manager/domain/entities/event.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';
import 'package:uman_event_manager/infrastructure/security/kdf_metadata.dart';

Uint8List testPassphrase() =>
    Uint8List.fromList(utf8.encode('phase1-test-passphrase'));

Event sampleEvent({
  String id = '11111111-1111-4111-8111-111111111111',
  String name = 'Uman 2026',
  bool deleted = false,
}) => Event(
  id: id,
  name: name,
  hebrewName: 'אומן תשפ״ז',
  description: 'EN / עברית',
  year: 2026,
  startDate: CivilDate(2026, 9, 9),
  endDate: CivilDate(2026, 9, 20),
  baseCurrency: 'USD',
  lifecycleStage: EventLifecycleStage.planning,
  managerNotes: 'Manager-entered notes',
  settings: {
    'timezone': 'Asia/Jerusalem',
    'nested': {
      'values': [1, true, null],
    },
  },
  createdAtUtc: DateTime.utc(2026, 9, 1, 10, 20, 30, 123, 456),
  updatedAtUtc: DateTime.utc(2026, 9, 2, 10, 20, 30, 654, 321),
  isDeleted: deleted,
  deletedAtUtc: deleted ? DateTime.utc(2026, 9, 3) : null,
  version: deleted ? 2 : 1,
  lastModifiedByDeviceId: 'test-device',
);

/// Test-only non-secret metadata persistence; native Keystore/Keychain is a
/// separate device gate, never claimed verified by this adapter.
final class FileMetadataStore implements KdfMetadataStore {
  FileMetadataStore(this.file);
  final File file;
  @override
  Future<KdfMetadata?> read() async => await file.exists()
      ? KdfMetadata.decode(await file.readAsString())
      : null;
  @override
  Future<void> write(KdfMetadata metadata) =>
      file.writeAsString(metadata.encode(), flush: true);
}
