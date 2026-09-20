import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/flights_repository.dart';
import 'flight_codec.dart';
import 'supabase_repositories.dart';

class SupabaseFlightsDataSource {
  SupabaseFlightsDataSource(this.client, this.eventId);
  final SupabaseClient client;
  final String eventId;
  final _signals = StreamController<RepositorySignal>.broadcast();
  RealtimeChannel? _flightChannel;
  RealtimeChannel? _passengerChannel;
  bool _disposed = false;

  Stream<RepositorySignal> get signals {
    _flightChannel ??= client
        .channel('flights-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'flights',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .subscribe(
          (status, _) => _signal(
            status == RealtimeSubscribeStatus.subscribed
                ? RepositorySignal.connected
                : RepositorySignal.disconnected,
          ),
        );

    _passengerChannel ??= client
        .channel('flight-passengers-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'flight_passengers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .subscribe();

    return _signals.stream;
  }

  void _signal(RepositorySignal signal) {
    if (!_disposed) _signals.add(signal);
  }

  Future<dynamic> rpc(String name, Map<String, Object?> parameters) => guarded(
        () => client.rpc(name, params: {'p_event_id': eventId, ...parameters}),
      );

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_flightChannel != null) await client.removeChannel(_flightChannel!);
    if (_passengerChannel != null) await client.removeChannel(_passengerChannel!);
    await _signals.close();
  }
}

class SupabaseFlightsRepository implements FlightsRepository {
  SupabaseFlightsRepository(this.source);
  final SupabaseFlightsDataSource source;

  @override
  String get eventId => source.eventId;

  @override
  Stream<RepositorySignal> get signals => source.signals;

  @override
  Future<List<Flight>> listFlights(String eventId,
      {bool includeDeleted = false}) async {
    final result = await source.rpc('list_flights', {
      'p_deleted': includeDeleted,
    });
    return (result as List)
        .map((r) => decodeFlight(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<Flight> readFlight(String eventId, String flightId) async {
    final result = await source.rpc('read_flight', {
      'p_id': flightId,
    });
    return decodeFlight(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<String> saveFlight({
    required String eventId,
    required String? flightId,
    required int? expectedVersion,
    required FlightInput fields,
    required String requestId,
  }) async {
    return await source.rpc('save_flight', {
      'p_request_id': requestId,
      'p_id': flightId,
      'p_expected_version': expectedVersion,
      'p_fields': fields.toJson(),
    }) as String;
  }

  @override
  Future<void> setFlightDeleted({
    required String eventId,
    required String flightId,
    required int expectedVersion,
    required bool deleted,
  }) async {
    await source.rpc('set_flight_deleted', {
      'p_id': flightId,
      'p_expected_version': expectedVersion,
      'p_deleted': deleted,
    });
  }

  @override
  Future<List<FlightPassenger>> listFlightPassengers(
      String eventId, String flightId) async {
    final result = await source.rpc('list_flight_passengers', {
      'p_flight_id': flightId,
    });
    return (result as List)
        .map((r) => decodeFlightPassenger(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<String> saveFlightPassenger({
    required String eventId,
    required String? passengerId,
    required int? expectedVersion,
    required FlightPassengerInput fields,
    required String requestId,
  }) async {
    return await source.rpc('save_flight_passenger', {
      'p_request_id': requestId,
      'p_id': passengerId,
      'p_expected_version': expectedVersion,
      'p_fields': fields.toJson(),
    }) as String;
  }

  @override
  Future<void> setFlightPassengerDeleted({
    required String eventId,
    required String passengerId,
    required int expectedVersion,
    required bool deleted,
  }) async {
    await source.rpc('set_flight_passenger_deleted', {
      'p_id': passengerId,
      'p_expected_version': expectedVersion,
      'p_deleted': deleted,
    });
  }

  @override
  Future<void> dispose() => source.dispose();
}
