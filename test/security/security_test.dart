import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/core/foundation_failure.dart';
import 'package:uman_event_manager/infrastructure/security/security_key_service.dart';
import 'package:uman_event_manager/infrastructure/security/kdf_metadata.dart';
import 'package:uman_event_manager/infrastructure/security/secure_kdf_metadata_store.dart';
import '../support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = SecurityKeyService();
  test(
    'PBKDF2 matches independent .NET SHA256/600000/32-byte vector',
    () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final key = await service.deriveKey(
        passphrase: testPassphrase(),
        salt: salt,
      );
      final hex = key.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
      expect(
        hex,
        '4d19f56147da552607bf6d66b725b23286b09de15c339e6be512361eb6bf777e',
      );
      expect(key.length, 32);
      final again = await service.deriveKey(
        passphrase: testPassphrase(),
        salt: salt,
      );
      expect(again, orderedEquals(key));
      salt[0] = 99;
      final changed = await service.deriveKey(
        passphrase: testPassphrase(),
        salt: salt,
      );
      expect(changed, isNot(orderedEquals(key)));
      for (final buffer in [key, again, changed]) {
        buffer.fillRange(0, buffer.length, 0);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test('Salts are random 16-byte values; invalid inputs fail safely', () async {
    final salts = List.generate(100, (_) => service.generateSalt());
    expect(salts.every((s) => s.length == 16), isTrue);
    expect(salts.map(base64Encode).toSet().length, 100);
    await expectLater(
      service.deriveKey(passphrase: testPassphrase(), salt: Uint8List(1)),
      throwsA(isA<FoundationFailure>()),
    );
  });
  test(
    'Metadata serializes only fixed KDF parameters; malformed data rejected',
    () {
      final metadata = KdfMetadata(service.generateSalt());
      expect(jsonDecode(metadata.encode()).keys.toSet(), {
        'version',
        'kdf',
        'iterations',
        'salt',
      });
      expect(KdfMetadata.decode(metadata.encode()).salt, metadata.salt);
      expect(
        () => KdfMetadata.decode(metadata.encode().replaceFirst('600000', '1')),
        throwsA(isA<FoundationFailure>()),
      );
      expect(
        () => KdfMetadata.decode('{"password":"do-not-report"}'),
        throwsA(
          isA<FoundationFailure>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('do-not-report')),
          ),
        ),
      );
    },
  );
  test(
    'Secure storage boundary writes metadata only and never resets on errors',
    () async {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final calls = <MethodCall>[];
      String? stored;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'write') {
              stored = call.arguments['value'] as String;
            }
            if (call.method == 'read') return stored;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final store = SecureKdfMetadataStore();
      final metadata = KdfMetadata(service.generateSalt());
      await store.write(metadata);
      expect((await store.read())!.salt, metadata.salt);
      expect(calls.map((c) => c.method), ['write', 'read']);
      expect(stored, isNot(contains('phase1-test-passphrase')));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(
              code: 'test',
              message: 'do-not-report-secret',
            ),
          );
      await expectLater(
        store.read(),
        throwsA(
          isA<FoundationFailure>()
              .having(
                (e) => e.kind,
                'kind',
                FoundationFailureKind.storageFailure,
              )
              .having(
                (e) => e.toString(),
                'safe',
                isNot(contains('do-not-report-secret')),
              ),
        ),
      );
    },
  );
}
