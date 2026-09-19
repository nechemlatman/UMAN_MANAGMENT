import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_codec.dart';

Future<T> guarded<T>(Future<T> Function() action) async {
  try {
    return await action().timeout(const Duration(seconds: 12));
  } on PostgrestException catch (e) {
    throw CloudFailure(switch (e.code) {
      '40001' => CloudFailureKind.conflict,
      '42501' || 'PGRST301' || 'PGRST303' => CloudFailureKind.unauthorized,
      '23514' ||
      '23502' ||
      '22023' ||
      '22007' ||
      '22008' ||
      '22P02' => CloudFailureKind.invalid,
      _ => CloudFailureKind.unknown,
    });
  } on AuthException {
    throw const CloudFailure(CloudFailureKind.unauthorized);
  } on SocketException {
    throw const CloudFailure(CloudFailureKind.unavailable);
  } on TimeoutException {
    throw const CloudFailure(CloudFailureKind.unavailable);
  } catch (_) {
    throw const CloudFailure(CloudFailureKind.unknown);
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<String?> get identities => client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct();
  @override
  Future<void> login(String email, String password) => guarded(() async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  });
  @override
  Future<void> logout() =>
      guarded(() => client.auth.signOut(scope: SignOutScope.local));
}

class SupabaseEventRepository implements EventRepository {
  SupabaseEventRepository(this.client) {
    _channel = client
        .channel('events-${client.auth.currentUser!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_members',
          callback: (_) => _signal(RepositorySignal.changed),
        )
        .subscribe(
          (status, error) => _signal(
            status == RealtimeSubscribeStatus.subscribed
                ? RepositorySignal.connected
                : RepositorySignal.disconnected,
          ),
        );
  }
  final SupabaseClient client;
  final _signals = StreamController<RepositorySignal>.broadcast();
  late final RealtimeChannel _channel;
  void _signal(RepositorySignal value) {
    if (!_signals.isClosed) _signals.add(value);
  }

  @override
  Stream<RepositorySignal> get signals => _signals.stream;
  @override
  Future<List<Event>> readAll() => guarded(() async {
    final result = <Event>[];
    for (var offset = 0; ; offset += 500) {
      final rows = await client
          .from('events')
          .select()
          .order('id')
          .range(offset, offset + 499);
      result.addAll(rows.map(decodeEvent));
      if (rows.length < 500) return result;
    }
  });
  @override
  Future<Event> create(NewEvent input) => guarded(
    () async => decodeEvent(
      Map<String, dynamic>.from(
        await client.rpc(
              'create_event',
              params: {
                'p_request_id': input.requestId,
                'p_name': input.name,
                'p_year': input.year,
                'p_start_date': input.startDate,
                'p_end_date': input.endDate,
                'p_base_currency': input.baseCurrency,
              },
            )
            as Map,
      ),
    ),
  );
  @override
  Future<Event> rename(String id, int expectedVersion, String name) => guarded(
    () async => decodeEvent(
      Map<String, dynamic>.from(
        await client.rpc(
              'update_event',
              params: {
                'p_id': id,
                'p_expected_version': expectedVersion,
                'p_name': name,
              },
            )
            as Map,
      ),
    ),
  );
  @override
  Future<Event> editDetails(
    String id,
    int expectedVersion,
    EventDetailsInput input,
  ) => _operation('edit_event_details', id, expectedVersion, {
    'p_name': input.name,
    'p_hebrew_name': input.hebrewName,
    'p_description': input.description,
    'p_manager_notes': input.managerNotes,
    'p_year': input.year,
    'p_start_date': input.startDate,
    'p_end_date': input.endDate,
    'p_base_currency': input.baseCurrency,
  });
  @override
  Future<Event> transition(
    String id,
    int expectedVersion,
    EventLifecycleStage stage,
  ) => _operation('transition_event', id, expectedVersion, {
    'p_stage': stage.storageValue,
  });
  @override
  Future<Event> archive(String id, int expectedVersion) =>
      _operation('archive_event', id, expectedVersion);
  @override
  Future<Event> softDelete(String id, int expectedVersion) =>
      _operation('soft_delete_event', id, expectedVersion);
  @override
  Future<Event> restore(String id, int expectedVersion) =>
      _operation('restore_event', id, expectedVersion);

  Future<Event> _operation(
    String operation,
    String id,
    int version, [
    Map<String, Object?> fields = const {},
  ]) => guarded(
    () async => decodeEvent(
      Map<String, dynamic>.from(
        await client.rpc(
              operation,
              params: {'p_id': id, 'p_expected_version': version, ...fields},
            )
            as Map,
      ),
    ),
  );

  @override
  Future<void> dispose() async {
    await client.removeChannel(_channel);
    await _signals.close();
  }
}
