import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../../domain/repositories/event_repository.dart';
import 'accommodation_codec.dart';
import 'supabase_repositories.dart';

class SupabaseAccommodationRepository implements AccommodationRepository {
  SupabaseAccommodationRepository(this.client, this.eventId);
  final SupabaseClient client;
  @override
  final String eventId;
  late final _signals = StreamController<RepositorySignal>.broadcast(
    onListen: _subscribe,
    onCancel: _unsubscribe,
  );
  RealtimeChannel? _channel;
  Future<void> _disconnecting = Future.value();
  bool _disposed = false;
  @override
  Stream<RepositorySignal> get signals =>
      _disposed ? const Stream.empty() : _signals.stream;
  Future<void> _subscribe() async {
    await _disconnecting;
    if (_disposed || !_signals.hasListener || _channel != null) return;
    var channel = client.channel(
      'accommodation-$eventId-${identityHashCode(this)}',
    );
    for (final table in [
      'apartments',
      'rooms',
      'sleeping_places',
      'accommodation_assignments',
      'people',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'event_id',
          value: eventId,
        ),
        callback: (_) => _signal(RepositorySignal.changed),
      );
    }
    _channel = channel.subscribe(
      (status, _) => _signal(
        status == RealtimeSubscribeStatus.subscribed
            ? RepositorySignal.connected
            : RepositorySignal.disconnected,
      ),
    );
  }

  void _signal(RepositorySignal signal) {
    if (!_disposed) _signals.add(signal);
  }

  Future<void> _unsubscribe() {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      _disconnecting = _disconnecting.then((_) async {
        await client.removeChannel(channel);
      });
    }
    return _disconnecting;
  }

  Future<dynamic> _rpc(String name, Map<String, Object?> params) {
    if (_disposed) throw const CloudFailure(CloudFailureKind.unavailable);
    return guarded(
      () => client.rpc(name, params: {'p_event_id': eventId, ...params}),
    );
  }

  void _scope(AccommodationRecord base) {
    if (base.eventId != eventId) {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
  }

  @override
  Future<AccommodationSnapshot> read() async {
    final data = await _rpc('read_accommodation', {});
    try {
      return decodeAccommodation(data as Map, eventId);
    } on FormatException {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
  }

  @override
  Future<String> save(
    AccommodationInput input, {
    required String requestId,
    AccommodationRecord? base,
  }) async {
    if (base != null) {
      _scope(base);
      if (base.input.kind != input.kind) {
        throw const CloudFailure(CloudFailureKind.invalid);
      }
    }
    try {
      input.validate();
    } on FormatException {
      throw const CloudFailure(CloudFailureKind.invalid);
    }
    return await _rpc('save_${input.kind.code}', {
          'p_request_id': requestId,
          'p_id': base?.id,
          'p_expected_version': base?.version,
          'p_fields': encodeAccommodation(input),
        })
        as String;
  }

  @override
  Future<void> setDeleted(AccommodationRecord base, bool deleted) async {
    _scope(base);
    await _rpc('${deleted ? 'delete' : 'restore'}_${base.input.kind.code}', {
      'p_id': base.id,
      'p_expected_version': base.version,
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _unsubscribe();
    await _signals.close();
  }
}
