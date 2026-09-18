import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

import '../../core/foundation_failure.dart';

final class SecurityKeyService {
  const SecurityKeyService();
  static const iterations = 600000;
  static const saltLength = 16;
  static const keyLength = 32;

  Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Caller owns its input/output buffers and must erase them after use.
  Future<Uint8List> deriveKey({
    required Uint8List passphrase,
    required Uint8List salt,
  }) async {
    if (passphrase.isEmpty || salt.length != saltLength) {
      throw const FoundationFailure(FoundationFailureKind.invalidKey);
    }
    final input = Uint8List.fromList(passphrase);
    final saltCopy = Uint8List.fromList(salt);
    try {
      return await Isolate.run(() => _derive(input, saltCopy));
    } catch (_) {
      throw const FoundationFailure(FoundationFailureKind.invalidKey);
    } finally {
      input.fillRange(0, input.length, 0);
    }
  }
}

Future<Uint8List> _derive(Uint8List input, Uint8List salt) async {
  final secret = SecretKeyData(input, overwriteWhenDestroyed: true);
  SecretKey? derived;
  try {
    derived = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: SecurityKeyService.iterations,
      bits: 256,
    ).deriveKey(secretKey: secret, nonce: salt);
    return Uint8List.fromList(await derived.extractBytes());
  } finally {
    secret.destroy();
    derived?.destroy();
    input.fillRange(0, input.length, 0);
  }
}
