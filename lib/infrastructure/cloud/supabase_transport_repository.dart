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
  final _signals = StreamController<RepositorySignal>.broadcast();
  RealtimeChannel? _driversChannel;
  RealtimeChannel? _vehiclesChannel;
  bool _disposed = false;

  Stream<RepositorySignal> get signals {
    _driversChannel ??= client
        .channel('drivers-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'drivers',
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

    _vehiclesChannel ??= client
        .channel('vehicles-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicles',
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
    if (_driversChannel != null) await client.removeChannel(_driversChannel!);
    if (_vehiclesChannel != null) await client.removeChannel(_vehiclesChannel!);
    await _signals.close();
  }
}

class SupabaseTransportRepository implements TransportRepository {
  SupabaseTransportRepository(this.source);
  final SupabaseTransportDataSource source;

  // --- DRIVERS ---
  @override
  Future<List<Driver>> listDrivers(
    String eventId, {
    String query = '',
    bool includeDeleted = false,
  }) async {
    final response = await source.rpc('list_drivers', {
      'p_query': query,
      'p_deleted': includeDeleted,
    });
    return (response as List)
        .map((row) => decodeDriver(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Driver?> readDriver(String eventId, String driverId) async {
    try {
      final response = await source.rpc('read_driver', {
        'p_id': driverId,
      });
      return decodeDriver(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> saveDriver(
    String eventId,
    DriverInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
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
    final response = await source.rpc('list_vehicles', {
      'p_query': query,
      'p_deleted': includeDeleted,
    });
    return (response as List)
        .map((row) => decodeVehicle(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Vehicle?> readVehicle(String eventId, String vehicleId) async {
    try {
      final response = await source.rpc('read_vehicle', {
        'p_id': vehicleId,
      });
      return decodeVehicle(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> saveVehicle(
    String eventId,
    VehicleInput input, {
    required String requestId,
    String? id,
    int? expectedVersion,
  }) async {
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
    await source.rpc('delete_vehicle', {
      'p_id': vehicleId,
      'p_expected_version': expectedVersion,
    });
  }
}
