import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'support/accommodation_fakes.dart';

import 'package:uman_event_manager/infrastructure/cloud/supabase_accommodation_repository.dart';
import 'support/people_fakes.dart' show peopleEvent;

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseAccommodationRepository repository;
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
    repository = SupabaseAccommodationRepository(client, peopleEvent);
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
      response = {
        'apartments': [],
        'rooms': [],
        'sleeping_places': [],
        'accommodation_assignments': [],
        'people': [],
        'overlaps': [],
      };
      expect((await repository.read()).apartments, isEmpty);
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
        await expectLater(repository.read(), failure(entry.value));
      }
    },
  );
  test(
    'save and restore send scope, explicit status, request and CAS version',
    () async {
      response = aptId;
      await repository.save(
        apartmentInput,
        requestId: aptId,
        base: accRecord(aptId, apartmentInput, version: 4),
      );
      expect(requests.last['p_expected_version'], 4);
      expect(requests.last['p_event_id'], peopleEvent);
      expect((requests.last['p_fields'] as Map)['status'], 'ACTIVE');
      response = null;
      await repository.setDeleted(
        accRecord(aptId, apartmentInput, version: 4),
        false,
      );
      expect(requests.last['p_expected_version'], 4);
    },
  );
  test(
    'SDK subscribes all five event-scoped dependencies and releases channel',
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
      expect(bindings.map((b) => b['table']), [
        'apartments',
        'rooms',
        'sleeping_places',
        'accommodation_assignments',
        'people',
      ]);
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
              'table': 'rooms',
              'type': 'UPDATE',
              'commit_timestamp': '2026-09-24T10:00:00Z',
              'columns': [],
              'record': {'id': roomId},
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
  test(
    'Cross-event read and mutation fail closed without sending a write',
    () async {
      response = {
        'apartments': [
          {'event_id': roomId},
        ],
        'rooms': [],
        'sleeping_places': [],
        'accommodation_assignments': [],
        'people': [],
        'overlaps': [],
      };
      await expectLater(
        repository.read(),
        failure(CloudFailureKind.unauthorized),
      );
      final count = requests.length;
      await expectLater(
        repository.save(
          apartmentInput,
          requestId: aptId,
          base: accRecord(aptId, apartmentInput, eventId: roomId),
        ),
        failure(CloudFailureKind.unauthorized),
      );
      expect(requests.length, count);
    },
  );
}
