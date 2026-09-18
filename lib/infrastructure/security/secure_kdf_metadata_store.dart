import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/foundation_failure.dart';
import 'kdf_metadata.dart';

/// Stores only the non-secret derivation parameters, never credentials/keys.
final class SecureKdfMetadataStore implements KdfMetadataStore {
  SecureKdfMetadataStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
              synchronizable: false,
            ),
          );
  static const storageKey = 'uman.database.kdf.v1';
  final FlutterSecureStorage _storage;
  @override
  Future<KdfMetadata?> read() async {
    try {
      final value = await _storage.read(key: storageKey);
      return value == null ? null : KdfMetadata.decode(value);
    } catch (_) {
      throw const FoundationFailure(FoundationFailureKind.storageFailure);
    }
  }

  @override
  Future<void> write(KdfMetadata metadata) async {
    try {
      await _storage.write(key: storageKey, value: metadata.encode());
    } catch (_) {
      throw const FoundationFailure(FoundationFailureKind.storageFailure);
    }
  }
}
