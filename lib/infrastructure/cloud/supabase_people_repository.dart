import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/people_repository.dart';
import 'person_codec.dart';
import 'supabase_repositories.dart';

/// Transport owns Supabase types; repositories expose domain data only.
class SupabasePeopleDataSource {
  SupabasePeopleDataSource(this.client, this.eventId);
  final SupabaseClient client;
  final String eventId;
  final _signals = StreamController<RepositorySignal>.broadcast();
  RealtimeChannel? _channel;
  bool _disposed = false;
  Stream<RepositorySignal> get signals {
    _channel ??= client
        .channel('people-$eventId-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'people',
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
    if (_channel != null) await client.removeChannel(_channel!);
    await _signals.close();
  }
}

class SupabasePeopleRepository implements PeopleRepository {
  SupabasePeopleRepository(this.source);
  final SupabasePeopleDataSource source;
  @override
  String get eventId => source.eventId;
  @override
  Stream<RepositorySignal> get signals => source.signals;
  List<PersonSummary> _rows(dynamic result) {
    final rows = (result as List)
        .map((r) => decodePersonSummary(Map<String, dynamic>.from(r as Map)))
        .toList();
    if (rows.any((r) => r.eventId != eventId)) {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
    return List.unmodifiable({for (final r in rows) r.id: r}.values);
  }

  @override
  Future<List<PersonSummary>> readPage({
    required String query,
    required bool deleted,
    required int limit,
    required int offset,
  }) async => _rows(
    await source.rpc('list_people', {
      'p_query': query,
      'p_deleted': deleted,
      'p_limit': limit,
      'p_offset': offset,
    }),
  );
  @override
  Future<Person> read(String id) async {
    final person = decodePerson(
      Map<String, dynamic>.from(
        await source.rpc('read_person', {'p_id': id}) as Map,
      ),
    );
    if (person.summary.eventId != eventId || person.summary.id != id) {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
    return person;
  }

  @override
  Future<List<PersonSummary>> duplicates(
    PersonInput input, {
    String? excludeId,
  }) async => _rows(
    await source.rpc('person_duplicates', {
      'p_fields': encodePersonInput(input),
      'p_exclude': excludeId,
    }),
  );
  @override
  Future<String> save(
    PersonInput input, {
    required String requestId,
    Person? base,
  }) async {
    if (input.validate().isNotEmpty || !input.customFieldsValid) {
      throw const CloudFailure(CloudFailureKind.invalid);
    }
    if (base != null && base.summary.eventId != eventId) {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
    return await source.rpc('save_person', {
          'p_request_id': requestId,
          'p_id': base?.summary.id,
          'p_expected_version': base?.summary.version,
          'p_fields': encodePersonInput(input),
        })
        as String;
  }

  @override
  Future<void> setDeleted(PersonSummary base, bool deleted) async {
    if (base.eventId != eventId) {
      throw const CloudFailure(CloudFailureKind.unauthorized);
    }
    await source.rpc('set_person_deleted', {
      'p_id': base.id,
      'p_expected_version': base.version,
      'p_deleted': deleted,
    });
  }

  @override
  Future<void> dispose() => source.dispose();
}
