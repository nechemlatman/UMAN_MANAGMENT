import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_codec.dart';

const cloudSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    synchronizable: false,
  ),
);

class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this.project);
  final String project;
  String get _key => 'uman.session.$project';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<String?> accessToken() => cloudSecureStorage.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      cloudSecureStorage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => cloudSecureStorage.delete(key: _key);
}

class SecureEventCache implements EventCache {
  SecureEventCache(String project, String userId)
    : _key = 'uman.cache.v1.$project.$userId';
  final String _key;
  @override
  Future<EventSnapshot?> read() async {
    try {
      final raw = await cloudSecureStorage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final time = DateTime.parse(json['at'] as String).toUtc();
      if (!EventSnapshot.isTimestampUsable(time, DateTime.now().toUtc())) {
        await clear();
        return null;
      }
      return EventSnapshot(
        (json['events'] as List)
            .map((e) => decodeEvent(Map<String, dynamic>.from(e as Map)))
            .toList(),
        time,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(EventSnapshot snapshot) => cloudSecureStorage.write(
    key: _key,
    value: jsonEncode({
      'at': snapshot.synchronizedAt.toIso8601String(),
      'events': snapshot.events.map(encodeEvent).toList(),
    }),
  );
  @override
  Future<void> clear() => cloudSecureStorage.delete(key: _key);
}
