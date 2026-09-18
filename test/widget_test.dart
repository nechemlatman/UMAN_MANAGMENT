import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/presentation/cloud_app.dart';
import 'dart:async';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/auth_repository.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache, sample;

class FakeAuth implements AuthRepository {
  String? id = 'user-a';
  final changes = StreamController<String?>.broadcast();
  @override
  String? get userId => id;
  @override
  Stream<String?> get identities => changes.stream;
  @override
  Future<void> login(String email, String password) async {
    id = 'user-a';
    changes.add(id);
  }

  @override
  Future<void> logout() async {
    id = null;
    changes.add(null);
  }
}

void main() {
  testWidgets(
    'Realtime preserves draft, conflict is explicit, logout clears cache',
    (tester) async {
      final auth = FakeAuth(), repo = FakeRepository(), cache = MemoryCache();
      var factories = 0;
      await tester.pumpWidget(
        CloudApp(
          auth: auth,
          createController: (_) {
            factories++;
            return EventController(repo, cache);
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Uman'), findsOneWidget);
      await tester.tap(find.text('Uman'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Preserved draft');
      repo.rows = [sample(2, 'Remote change')];
      repo.notifications.add(RepositorySignal.changed);
      await tester.pumpAndSettle();
      expect(find.text('Preserved draft'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Preserved draft'), findsOneWidget);
      expect(find.textContaining('Your text is kept here'), findsOneWidget);
      expect(repo.rows.single.name, 'Remote change');
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Remote change'), findsOneWidget);
      expect(factories, 1);
      await tester.runAsync(() async {
        final signedOut = auth.changes.stream.firstWhere((id) => id == null);
        await tester.tap(find.text('Sign out'));
        await signedOut.timeout(const Duration(seconds: 3));
      });
      await tester.pumpAndSettle();
      expect(
        auth.id,
        isNull,
        reason: 'Logout must complete before login screen appears',
      );
      expect(find.text('Sign in'), findsOneWidget);
      expect(cache.snapshot, isNull);
      await tester.pumpWidget(const SizedBox());
      await auth.changes.close();
    },
  );
  testWidgets(
    'Missing configuration fails safely without a local writable mode',
    (tester) async {
      await tester.pumpWidget(const CloudApp());
      expect(find.text('Cloud configuration required.'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
}
