import 'package:uman_event_manager/domain/entities/task.dart';
import 'package:uman_event_manager/infrastructure/cloud/task_codec.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'support/task_fakes.dart';

import 'package:uman_event_manager/infrastructure/cloud/supabase_tasks_repository.dart';
import 'support/people_fakes.dart' show peopleEvent;

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseTasksRepository repository;
  Object? response;
  WebSocket? socket;
  List<dynamic>? joined;
  var status = 200;
  final requests = <Map<String, dynamic>>[];
  setUp(() async {
    socket = null;
    joined = null;
    status = 200;
    response = null;
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final ws = await WebSocketTransformer.upgrade(request);
        socket = ws;
        ws.listen((raw) {
          final frame = jsonDecode(raw as String) as List;
          if (frame[3] == 'phx_join') {
            joined = frame;
            final bindings = (frame[4]['config']['postgres_changes'] as List);
            ws.add(
              jsonEncode([
                frame[0],
                frame[1],
                frame[2],
                'phx_reply',
                {
                  'status': 'ok',
                  'response': {
                    'postgres_changes': [
                      for (var i = 0; i < bindings.length; i++)
                        {...bindings[i] as Map, 'id': i},
                    ],
                  },
                },
              ]),
            );
          } else if (frame[3] == 'phx_leave') {
            ws.add(
              jsonEncode([
                frame[0],
                frame[1],
                frame[2],
                'phx_reply',
                {'status': 'ok', 'response': {}},
              ]),
            );
          }
        });
        return;
      }
      requests.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>,
      );
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = SupabaseTasksRepository(client, peopleEvent);
  });
  tearDown(() async {
    await repository.dispose();
    await client.dispose();
    await server.close(force: true);
  });
  Matcher failure(CloudFailureKind kind) =>
      throwsA(isA<CloudFailure>().having((e) => e.kind, 'kind', kind));
  test(
    'RPC errors retain deterministic classification and authorized absence',
    () async {
      expect(await repository.readTask('missing'), isNull);
      for (final entry in {
        '42501': CloudFailureKind.unauthorized,
        '40001': CloudFailureKind.conflict,
        '503': CloudFailureKind.unavailable,
        '22023': CloudFailureKind.invalid,
        '23503': CloudFailureKind.invalid,
        '23505': CloudFailureKind.invalid,
        'unexpected': CloudFailureKind.unknown,
      }.entries) {
        status = 400;
        response = {'code': entry.key, 'message': 'private error'};
        await expectLater(repository.readTask('id'), failure(entry.value));
      }
    },
  );
  test(
    'save and restore send scope, explicit status, request and CAS version',
    () async {
      response = taskId;
      await repository.saveTask(
        const TaskInput(title: 'Arrange arrival'),
        requestId: taskId,
        base: taskSample(version: 4),
      );
      expect(requests.last['p_expected_version'], 4);
      expect(requests.last['p_event_id'], peopleEvent);
      expect((requests.last['p_fields'] as Map)['priority'], isNull);
      expect((requests.last['p_fields'] as Map).containsKey('status'), false);
      response = null;
      await repository.transition(
        taskSample(version: 4),
        TaskStatus.inProgress,
      );
      expect(requests.last['p_status'], 'IN_PROGRESS');
      response = null;
      await repository.setDeleted(taskSample(version: 4), false);
      expect(requests.last['p_expected_version'], 4);
    },
  );
  test(
    'Mapping preserves UTC, nullable fields and server lifecycle evidence',
    () async {
      final row = {
        'id': taskId,
        'event_id': peopleEvent,
        'title': 'Hebrew עברית',
        'description': null,
        'assignee_id': null,
        'priority': 'HIGH',
        'due_date_utc': '2026-09-30T12:00:00+03:00',
        'status': 'COMPLETED',
        'completed_at_utc': '2026-09-30T09:10:00Z',
        'cancelled_at_utc': null,
        'is_deleted': false,
        'deleted_at_utc': null,
        'notes': null,
        'created_by': peopleEvent,
        'updated_by': peopleEvent,
        'created_at_utc': '2026-09-01T10:00:00Z',
        'updated_at_utc': '2026-09-30T09:10:00Z',
        'version': 8,
      };
      response = [row];
      final task = (await repository.listTasks()).single;
      expect(task.status, TaskStatus.completed);
      expect(task.input.dueDateUtc, DateTime.utc(2026, 9, 30, 9));
      expect(task.completedAtUtc, DateTime.utc(2026, 9, 30, 9, 10));
      expect(task.input.assigneeId, isNull);
      expect(
        () => decodeTask({...row, 'status': 'UNRECOGNIZED'}),
        throwsStateError,
      );
      response = [
        {...row, 'event_id': 'other'},
      ];
      await expectLater(
        repository.listTasks(),
        failure(CloudFailureKind.unauthorized),
      );
    },
  );
  test(
    'SDK subscribes Tasks and People event-scoped dependencies and releases channel',
    () async {
      final signals = <RepositorySignal>[];
      final connected = Completer<void>();
      final changed = Completer<void>();
      final subscription = repository.signals.listen((signal) {
        signals.add(signal);
        if (signal == RepositorySignal.connected && !connected.isCompleted) {
          connected.complete();
        }
        if (signal == RepositorySignal.changed && !changed.isCompleted) {
          changed.complete();
        }
      });
      await connected.future.timeout(const Duration(seconds: 5));
      final frame = joined!;
      final bindings = frame[4]['config']['postgres_changes'] as List;
      expect(bindings.map((b) => b['table']), ['tasks', 'people']);
      expect(
        bindings.every((b) => b['filter'] == 'event_id=eq.$peopleEvent'),
        true,
      );
      socket!.add(
        jsonEncode([
          frame[0],
          null,
          frame[2],
          'postgres_changes',
          {
            'ids': [1],
            'data': {
              'schema': 'public',
              'table': 'people',
              'type': 'UPDATE',
              'commit_timestamp': '2026-09-24T10:00:00Z',
              'columns': [],
              'record': {'id': 'vehicle'},
              'old_record': {},
            },
          },
        ]),
      );
      await changed.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();
      await repository.dispose();
      expect(client.getChannels(), isEmpty);
      expect(
        signals,
        containsAllInOrder([
          RepositorySignal.connected,
          RepositorySignal.changed,
        ]),
      );
    },
  );
}
