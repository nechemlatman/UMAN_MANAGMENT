import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/transport_repository.dart';
import 'driver_codec.dart';
import 'supabase_repositories.dart';
import 'vehicle_codec.dart';

class SupabaseTransportDataSource {
  SupabaseTransportDataSource(this.client, this.eventId);
  final SupabaseClient client;
  final String eventId;
  late final _signals = StreamController<RepositorySignal>.broadcast(
    onListen: _subscribe, onCancel: _unsubscribe);
  RealtimeChannel? _driversChannel;
  bool _disposed = false;

  Stream<RepositorySignal> get signals => _disposed ? const Stream.empty() : _signals.stream;

  void _subscribe() {
    if (_disposed) return;
    // One channel tracks both tables, so connected means the entire slice subscribed.
    _driversChannel ??= client
        .channel('transport-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, schema: 'public', table: 'drivers',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq,
            column: 'event_id', value: eventId),
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all, schema: 'public', table: 'vehicles',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq,
            column: 'event_id', value: eventId),
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .subscribe((status, _) => _signal(
          status == RealtimeSubscribeStatus.subscribed
              ? RepositorySignal.connected : RepositorySignal.disconnected));
  }

  void _signal(RepositorySignal signal) {
    if (!_disposed) _signals.add(signal);
  }

  Future<dynamic> rpc(String name, Map<String, Object?> parameters) => guarded(
        () => client.rpc(name, params: {'p_event_id': eventId, ...parameters}),
      );

  Future<void> _unsubscribe() async {
    final channel = _driversChannel;
    _driversChannel = null;
    if (channel != null) await client.removeChannel(channel);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _unsubscribe();
    await _signals.close();
  }
}

class SupabaseTransportRepository implements TransportRepository {
  SupabaseTransportRepository(this.source);
  final SupabaseTransportDataSource source;

  @override
  String get eventId => source.eventId;
  @override
  Stream<RepositorySignal> get signals => source.signals;
  @override
  Future<void> dispose() => source.dispose();

  void _checkScope(String id) {
    if (id != eventId) throw const CloudFailure(CloudFailureKind.unauthorized);
  }

  // --- DRIVERS ---
  @override
  Future<List<Driver>> listDrivers(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  }) async {
    _checkScope(eventId);
    final response = await source.rpc('list_drivers', {
      'p_query': query,
      'p_deleted': includeDeleted,
    });
    return (response as List)
        .map((row) { final value = decodeDriver(row as Map<String, dynamic>); _checkScope(value.eventId); return value; })
        .toList();
  }

  @override
  Future<Driver?> readDriver(String eventId, String driverId) async {
    _checkScope(eventId);
    final response = await source.rpc('read_driver', {'p_id': driverId});
    if (response == null) return null;
    final value = decodeDriver(response as Map<String, dynamic>);
    _checkScope(value.eventId);
    return value;
  }

  @override
  Future<String> saveDriver(
    String eventId,
    DriverInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
    _checkScope(eventId);
    final response = await source.rpc('save_driver', {
      'p_request_id': requestId,
      'p_id': id,
      'p_expected_version': expectedVersion,
      'p_fields': input.toJson(),
    });
    return response as String;
  }

  @override
  Future<void> deleteDriver(
    String eventId,
    String driverId, {
    required int expectedVersion,
  }) async {
    _checkScope(eventId);
    await source.rpc('delete_driver', {
      'p_id': driverId,
      'p_expected_version': expectedVersion,
    });
  }

  // --- VEHICLES ---
  @override
  Future<List<Vehicle>> listVehicles(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  }) async {
    _checkScope(eventId);
    final response = await source.rpc('list_vehicles', {
      'p_query': query,
      'p_deleted': includeDeleted,
    });
    return (response as List)
        .map((row) { final value = decodeVehicle(row as Map<String, dynamic>); _checkScope(value.eventId); return value; })
        .toList();
  }

  @override
  Future<Vehicle?> readVehicle(String eventId, String vehicleId) async {
    _checkScope(eventId);
    final response = await source.rpc('read_vehicle', {'p_id': vehicleId});
    if (response == null) return null;
    final value = decodeVehicle(response as Map<String, dynamic>);
    _checkScope(value.eventId);
    return value;
  }

  @override
  Future<String> saveVehicle(
    String eventId,
    VehicleInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
    _checkScope(eventId);
    final response = await source.rpc('save_vehicle', {
      'p_request_id': requestId,
      'p_id': id,
      'p_expected_version': expectedVersion,
      'p_fields': input.toJson(),
    });
    return response as String;
  }

  @override
  Future<void> deleteVehicle(
    String eventId,
    String vehicleId, {
    required int expectedVersion,
  }) async {
    _checkScope(eventId);
    await source.rpc('delete_vehicle', {
      'p_id': vehicleId,
      'p_expected_version': expectedVersion,
    });
  }
  @override
  Future<void> restoreDriver(String eventId, String id, {required int expectedVersion}) async {
    _checkScope(eventId);
    await source.rpc('restore_driver', {'p_id': id, 'p_expected_version': expectedVersion});
  }
  @override
  Future<void> restoreVehicle(String eventId, String id, {required int expectedVersion}) async {
    _checkScope(eventId);
    await source.rpc('restore_vehicle', {'p_id': id, 'p_expected_version': expectedVersion});
  }
}
