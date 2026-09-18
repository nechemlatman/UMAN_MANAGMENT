import 'dart:convert';
import 'dart:typed_data';
import '../../core/foundation_failure.dart';
import 'security_key_service.dart';

final class KdfMetadata {
  KdfMetadata(Uint8List salt) : _salt = Uint8List.fromList(salt) {
    if (salt.length != SecurityKeyService.saltLength) {
      throw const FoundationFailure(FoundationFailureKind.storageFailure);
    }
  }
  final Uint8List _salt;
  Uint8List get salt => Uint8List.fromList(_salt);

  String encode() => jsonEncode({
    'version': 1,
    'kdf': 'PBKDF2-HMAC-SHA256',
    'iterations': SecurityKeyService.iterations,
    'salt': base64Encode(_salt),
  });

  factory KdfMetadata.decode(String encoded) {
    try {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      if (map.length != 4 ||
          map['version'] != 1 ||
          map['kdf'] != 'PBKDF2-HMAC-SHA256' ||
          map['iterations'] != SecurityKeyService.iterations) {
        throw const FormatException();
      }
      return KdfMetadata(base64Decode(map['salt'] as String));
    } catch (_) {
      throw const FoundationFailure(FoundationFailureKind.storageFailure);
    }
  }
}

abstract interface class KdfMetadataStore {
  Future<KdfMetadata?> read();
  Future<void> write(KdfMetadata metadata);
}
