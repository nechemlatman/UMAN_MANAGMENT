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
  var status = 200;
  final requests = <Map<String, dynamic>>[];
  setUp(() async {
    status = 200; response = null; requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>);
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false));
    repository = SupabaseTransportRepository(SupabaseTransportDataSource(client, peopleEvent));
  });
  tearDown(() async { await repository.dispose(); await client.dispose(); await server.close(force: true); });
  Matcher failure(CloudFailureKind kind) => throwsA(isA<CloudFailure>().having((e) => e.kind, 'kind', kind));
  test('only an authorized absent row becomes null', () async {
    expect(await repository.readDriver(peopleEvent, 'missing'), isNull);
    expect(await repository.readVehicle(peopleEvent, 'missing'), isNull);
    for (final entry in {'42501': CloudFailureKind.unauthorized,
      '40001': CloudFailureKind.conflict, '503': CloudFailureKind.unavailable,
      '22023': CloudFailureKind.invalid, 'unexpected': CloudFailureKind.unknown}.entries) {
      status = 400; response = {'code': entry.key, 'message': 'private error'};
      await expectLater(repository.readDriver(peopleEvent, 'id'), failure(entry.value));
      await expectLater(repository.readVehicle(peopleEvent, 'id'), failure(entry.value));
    }
  });
  test('scope mismatch is rejected before any request', () async {
    await expectLater(repository.listDrivers('other'), failure(CloudFailureKind.unauthorized));
    await expectLater(repository.restoreVehicle('other', 'id', expectedVersion: 2), failure(CloudFailureKind.unauthorized));
    expect(requests, isEmpty);
  });
  test('save serializes operational fields and CAS; restore transmits scope and version', () async {
    response = 'id';
    await repository.saveDriver(peopleEvent, const DriverInput(fullName: 'Driver',
      whatsappPhone: '123', status: DriverStatus.busy), requestId: 'stable', id: 'id', expectedVersion: 3);
    expect(requests.last['p_request_id'], 'stable');
    expect(requests.last['p_expected_version'], 3);
    expect((requests.last['p_fields'] as Map)['whatsapp_phone'], '123');
    expect((requests.last['p_fields'] as Map)['status'], 'BUSY');
    await repository.saveVehicle(peopleEvent, const VehicleInput(name: 'Van',
      color: 'Blue', status: VehicleStatus.inUse), requestId: 'stable2');
    expect((requests.last['p_fields'] as Map)['color'], 'Blue');
    expect((requests.last['p_fields'] as Map)['status'], 'IN_USE');
    response = null;
    await repository.restoreDriver(peopleEvent, 'id', expectedVersion: 4);
    expect(requests.last, {'p_event_id': peopleEvent, 'p_id': 'id', 'p_expected_version': 4});
  });
}
