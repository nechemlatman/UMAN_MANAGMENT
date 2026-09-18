import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/infrastructure/cloud/cloud_config.dart';
import 'package:uman_event_manager/infrastructure/cloud/event_codec.dart';
import 'package:uman_event_manager/infrastructure/cloud/secure_cloud_storage.dart';
import 'cloud_controller_test.dart' show sample;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};
  setUp(() {
    values.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final key = call.arguments['key'] as String;
          switch (call.method) {
            case 'write':
              values[key] = call.arguments['value'] as String;
              return null;
            case 'read':
              return values[key];
            case 'delete':
              values.remove(key);
              return null;
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('Configuration rejects plaintext URLs and privileged client keys', () {
    expect(
      const CloudConfig(
        'http://project.supabase.co',
        'sb_publishable_public',
      ).isValid,
      false,
    );
    expect(
      const CloudConfig(
        'https://project.supabase.co',
        'sb_secret_backend',
      ).isValid,
      false,
    );
    expect(
      const CloudConfig(
        'https://project.supabase.co',
        'legacy-service-role-jwt',
      ).isValid,
      false,
    );
    expect(
      const CloudConfig(
        'https://project.supabase.co',
        'sb_publishable_public',
      ).isValid,
      true,
    );
  });
  test(
    'Session persists only through secure storage and logout removes it',
    () async {
      final store = SecureSessionStorage('project');
      expect(await store.hasAccessToken(), false);
      await store.persistSession('test-session');
      expect(await store.accessToken(), 'test-session');
      expect(await SecureSessionStorage('other-project').accessToken(), isNull);
      await store.removePersistedSession();
      expect(await store.hasAccessToken(), false);
    },
  );
  test(
    'Cache is partitioned by both user and project and clears independently',
    () async {
      final a = SecureEventCache('p', 'a'), b = SecureEventCache('p', 'b');
      await a.write(EventSnapshot([sample()], DateTime.now().toUtc()));
      expect((await a.read())!.events.single, sample());
      expect(await b.read(), isNull);
      expect(await SecureEventCache('other', 'a').read(), isNull);
      await a.clear();
      expect(await a.read(), isNull);
    },
  );
  test(
    'Corrupt, future-dated and expired cache cannot become current state',
    () async {
      final cache = SecureEventCache('p', 'a');
      values['uman.cache.v1.p.a'] = 'not-json';
      expect(await cache.read(), isNull);
      for (final time in [
        DateTime.now().toUtc().subtract(const Duration(days: 2)),
        DateTime.now().toUtc().add(const Duration(days: 1)),
      ]) {
        values['uman.cache.v1.p.a'] = jsonEncode({
          'at': time.toIso8601String(),
          'events': [encodeEvent(sample())],
        });
        expect(await cache.read(), isNull);
        expect(values, isEmpty);
      }
    },
  );
}
