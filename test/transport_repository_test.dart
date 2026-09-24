import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/entities/driver.dart';
import 'package:uman_event_manager/domain/entities/vehicle.dart';
import 'package:uman_event_manager/infrastructure/cloud/supabase_transport_repository.dart';
import 'support/people_fakes.dart' show peopleEvent;

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseTransportRepository repository;
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
    repository = SupabaseTransportRepository(
      SupabaseTransportDataSource(client, peopleEvent),
    );
  });
  tearDown(() async {
    await repository.dispose();
    await client.dispose();
    await server.close(force: true);
  });
  Matcher failure(CloudFailureKind kind) =>
      throwsA(isA<CloudFailure>().having((e) => e.kind, 'kind', kind));
  test('only an authorized absent row becomes null', () async {
    expect(await repository.readDriver(peopleEvent, 'missing'), isNull);
    expect(await repository.readVehicle(peopleEvent, 'missing'), isNull);
    for (final entry in {
      '42501': CloudFailureKind.unauthorized,
      '40001': CloudFailureKind.conflict,
      '503': CloudFailureKind.unavailable,
      '22023': CloudFailureKind.invalid,
      'unexpected': CloudFailureKind.unknown,
    }.entries) {
      status = 400;
      response = {'code': entry.key, 'message': 'private error'};
      await expectLater(
        repository.readDriver(peopleEvent, 'id'),
        failure(entry.value),
      );
      await expectLater(
        repository.readVehicle(peopleEvent, 'id'),
        failure(entry.value),
      );
    }
  });
  test('scope mismatch is rejected before any request', () async {
    await expectLater(
      repository.listDrivers('other'),
      failure(CloudFailureKind.unauthorized),
    );
    await expectLater(
      repository.restoreVehicle('other', 'id', expectedVersion: 2),
      failure(CloudFailureKind.unauthorized),
    );
    expect(requests, isEmpty);
  });
  test(
    'save serializes operational fields and CAS; restore transmits scope and version',
    () async {
      response = 'id';
      await repository.saveDriver(
        peopleEvent,
        const DriverInput(
          fullName: 'Driver',
          whatsappPhone: '123',
          status: DriverStatus.busy,
        ),
        requestId: 'stable',
        id: 'id',
        expectedVersion: 3,
      );
      expect(requests.last['p_request_id'], 'stable');
      expect(requests.last['p_expected_version'], 3);
      expect((requests.last['p_fields'] as Map)['whatsapp_phone'], '123');
      expect((requests.last['p_fields'] as Map)['status'], 'BUSY');
      await repository.saveVehicle(
        peopleEvent,
        const VehicleInput(
          name: 'Van',
          color: 'Blue',
          status: VehicleStatus.inUse,
        ),
        requestId: 'stable2',
      );
      expect((requests.last['p_fields'] as Map)['color'], 'Blue');
      expect((requests.last['p_fields'] as Map)['status'], 'IN_USE');
      response = null;
      await repository.restoreDriver(peopleEvent, 'id', expectedVersion: 4);
      expect(requests.last, {
        'p_event_id': peopleEvent,
        'p_id': 'id',
        'p_expected_version': 4,
      });
    },
  );

  test(
    'SDK subscribes both event-scoped tables, emits changes and releases channel',
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
      expect(bindings.map((b) => b['table']), ['drivers', 'vehicles']);
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
              'table': 'vehicles',
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
