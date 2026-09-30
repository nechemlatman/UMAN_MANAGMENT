import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/tasks_repository.dart';
import 'task_codec.dart';
import 'supabase_repositories.dart';

class SupabaseTasksRepository implements TasksRepository {
  SupabaseTasksRepository(this.client, this.eventId);
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
    var channel = client.channel('tasks-$eventId-${identityHashCode(this)}');
    for (final table in ['tasks', 'people']) {
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
  Future<List<EventTask>> listTasks({
    String query = '',
    bool deleted = false,
  }) async {
    final rows =
        await _rpc('list_tasks', {'p_query': query, 'p_deleted': deleted})
            as List;
    return rows.map((r) {
      final task = decodeTask(Map<String, dynamic>.from(r));
      _scope(task.eventId);
      return task;
    }).toList();
  }

  @override
  Future<EventTask?> readTask(String id) async {
    final row = await _rpc('read_task', {'p_id': id});
    if (row == null) return null;
    final task = decodeTask(Map<String, dynamic>.from(row));
    _scope(task.eventId);
    return task;
  }

  @override
  Future<List<TaskAssignee>> assignees() async {
    final rows = await _rpc('task_assignees', {}) as List;
    return rows
        .map(
          (r) => TaskAssignee(
            r['id'] as String,
            r['label'] as String,
            isDeleted: r['is_deleted'] as bool,
          ),
        )
        .toList();
  }

  @override
  Future<String> saveTask(
    TaskInput input, {
    required String requestId,
    EventTask? base,
  }) async {
    if (base != null) _scope(base.eventId);
    try {
      input.validate();
    } on FormatException {
      throw const CloudFailure(CloudFailureKind.invalid);
    }
    return await _rpc('save_task', {
          'p_request_id': requestId,
          'p_id': base?.id,
          'p_expected_version': base?.version,
          'p_fields': encodeTask(input),
        })
        as String;
  }

  @override
  Future<void> transition(EventTask base, TaskStatus status) async {
    _scope(base.eventId);
    await _rpc('transition_task', {
      'p_id': base.id,
      'p_expected_version': base.version,
      'p_status': status.code,
    });
  }

  @override
  Future<void> setDeleted(EventTask base, bool deleted) async {
    _scope(base.eventId);
    await _rpc(deleted ? 'delete_task' : 'restore_task', {
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
