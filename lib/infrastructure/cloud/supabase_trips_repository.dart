import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/trips_repository.dart';
import 'trip_codec.dart';
import 'supabase_repositories.dart';

class SupabaseTripsRepository implements TripsRepository {
  SupabaseTripsRepository(this.client, this.eventId);
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
    var channel = client.channel('trips-$eventId-${identityHashCode(this)}');
    for (final table in [
      'trips',
      'trip_passengers',
      'flights',
      'vehicles',
      'drivers',
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

  void _signal(RepositorySignal s) {
    if (!_disposed) _signals.add(s);
  }

  Future<void> _unsubscribe() {
    final c = _channel;
    _channel = null;
    if (c != null) {
      _disconnecting = _disconnecting.then((_) async {
        await client.removeChannel(c);
      });
    }
    return _disconnecting;
  }

  Future<dynamic> _rpc(String name, Map<String, Object?> p) =>
      guarded(() => client.rpc(name, params: {'p_event_id': eventId, ...p}));
  void _scope(String id) {
    if (id != eventId) throw const CloudFailure(CloudFailureKind.unauthorized);
  }

  @override
  Future<List<Trip>> listTrips({
    String query = '',
    bool deleted = false,
  }) async {
    final rows =
        await _rpc('list_trips', {'p_query': query, 'p_deleted': deleted})
            as List;
    return rows.map((r) {
      final t = decodeTrip(Map<String, dynamic>.from(r));
      _scope(t.eventId);
      return t;
    }).toList();
  }

  @override
  Future<Trip?> readTrip(String id) async {
    final row = await _rpc('read_trip', {'p_id': id});
    if (row == null) return null;
    final t = decodeTrip(Map<String, dynamic>.from(row));
    _scope(t.eventId);
    return t;
  }

  @override
  Future<List<TripPassenger>> listPassengers(
    String tripId, {
    bool deleted = false,
  }) async {
    final rows =
        await _rpc('list_trip_passengers', {
              'p_trip_id': tripId,
              'p_deleted': deleted,
            })
            as List;
    return rows.map((r) {
      final p = decodeTripPassenger(Map<String, dynamic>.from(r));
      _scope(p.eventId);
      if (p.input.tripId != tripId) {
        throw const CloudFailure(CloudFailureKind.unauthorized);
      }
      return p;
    }).toList();
  }

  @override
  Future<Map<String, List<TripAssignmentOption>>> assignmentOptions() async {
    final data = await _rpc('trip_assignment_options', {}) as Map;
    return {
      for (final key in ['drivers', 'vehicles', 'flights', 'people'])
        key: (data[key] as List)
            .map((r) => TripAssignmentOption(r['id'], r['label']))
            .toList(),
    };
  }

  @override
  Future<String> saveTrip(
    TripInput input, {
    required String requestId,
    Trip? base,
  }) async {
    if (base != null) _scope(base.eventId);
    try {
      input.validate();
    } on FormatException {
      throw const CloudFailure(CloudFailureKind.invalid);
    }
    return await _rpc('save_trip', {
          'p_request_id': requestId,
          'p_id': base?.id,
          'p_expected_version': base?.version,
          'p_fields': encodeTrip(input),
        })
        as String;
  }

  @override
  Future<String> savePassenger(
    TripPassengerInput input, {
    required String requestId,
    TripPassenger? base,
  }) async {
    if (base != null) _scope(base.eventId);
    try {
      input.validate();
    } on FormatException {
      throw const CloudFailure(CloudFailureKind.invalid);
    }
    return await _rpc('save_trip_passenger', {
          'p_request_id': requestId,
          'p_id': base?.id,
          'p_expected_version': base?.version,
          'p_fields': encodeTripPassenger(input),
        })
        as String;
  }

  @override
  Future<void> setTripDeleted(Trip base, bool deleted) async {
    _scope(base.eventId);
    await _rpc(deleted ? 'delete_trip' : 'restore_trip', {
      'p_id': base.id,
      'p_expected_version': base.version,
    });
  }

  @override
  Future<void> setPassengerDeleted(TripPassenger base, bool deleted) async {
    _scope(base.eventId);
    await _rpc(deleted ? 'delete_trip_passenger' : 'restore_trip_passenger', {
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
