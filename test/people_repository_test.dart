import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/infrastructure/cloud/person_codec.dart';
import 'package:uman_event_manager/infrastructure/cloud/supabase_people_repository.dart';
import 'support/people_fakes.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabasePeopleRepository repo;
  late Object response;
  late int status;
  final requests = <(String, Map<String, dynamic>)>[];
  Map<String, Object?> row() => {
    ...encodePersonInput(personFixture().input),
    'id': personFixture().summary.id,
    'event_id': peopleEvent,
    'version': 1,
    'is_deleted': false,
    'updated_at_utc': '2026-09-20T00:00:00Z',
    'created_at_utc': '2026-09-20T00:00:00Z',
    'created_by': peopleEvent,
    'updated_by': peopleEvent,
  };
  setUp(() async {
    requests.clear();
    status = 200;
    response = [row()];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      requests.add((request.uri.path, Map<String, dynamic>.from(body)));
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
    repo = SupabasePeopleRepository(
      SupabasePeopleDataSource(client, peopleEvent),
    );
  });
  tearDown(() async {
    await repo.dispose();
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'SDK transport sends event, query, deletion and bounded pagination on every list read',
    () async {
      final rows = await repo.readPage(
        query: 'דוד',
        deleted: true,
        limit: 51,
        offset: 50,
      );
      expect(rows.single.eventId, peopleEvent);
      expect(requests.single.$1, '/rest/v1/rpc/list_people');
      expect(requests.single.$2, {
        'p_event_id': peopleEvent,
        'p_query': 'דוד',
        'p_deleted': true,
        'p_limit': 51,
        'p_offset': 50,
      });
    },
  );
  test(
    'SDK writes carry expected version and stable request; protected details map separately',
    () async {
      response = personFixture().summary.id;
      await repo.save(
        personFixture().input,
        requestId: 'stable',
        base: personFixture(),
      );
      expect(requests.last.$2['p_expected_version'], 1);
      expect(requests.last.$2['p_request_id'], 'stable');
      expect(
        (requests.last.$2['p_fields'] as Map)['passport_expiration_date'],
        '2030-02-28',
      );
      response = row();
      final person = await repo.read(personFixture().summary.id);
      expect(person.summary.id, personFixture().summary.id);
      expect(requests.last.$2['p_event_id'], peopleEvent);
    },
  );
  test(
    'foreign event response and cross-event mutation are rejected',
    () async {
      response = [
        {...row(), 'event_id': 'other'},
      ];
      await expectLater(
        repo.readPage(query: '', deleted: false, limit: 51, offset: 0),
        throwsA(
          isA<CloudFailure>().having(
            (e) => e.kind,
            'kind',
            CloudFailureKind.unauthorized,
          ),
        ),
      );
      final count = requests.length;
      await expectLater(
        repo.setDeleted(personFixture(eventId: 'other').summary, true),
        throwsA(isA<CloudFailure>()),
      );
      expect(requests.length, count);
    },
  );
  test('SDK SQL error is converted to a safe domain failure', () async {
    status = 409;
    response = {
      'code': '40001',
      'message': 'raw SQL details must not escape',
      'details': null,
      'hint': null,
    };
    await expectLater(
      repo.save(
        personFixture().input,
        requestId: 'stable',
        base: personFixture(),
      ),
      throwsA(
        isA<CloudFailure>().having(
          (e) => e.kind,
          'kind',
          CloudFailureKind.conflict,
        ),
      ),
    );
  });
}
