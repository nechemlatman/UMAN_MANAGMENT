import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/trips_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/presentation/design_system.dart';
import 'package:uman_event_manager/presentation/transport/trips_page.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/trip_fakes.dart';

void main() {
  late EventController events;
  late FakeTripsRepository repo;
  late TripsController controller;
  setUp(() async {
    events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    repo = FakeTripsRepository();
    repo.rows = [tripSample(count: 2, review: true)];
    controller = TripsController(repo, events);
    await controller.start();
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  for (final direction in TextDirection.values) {
    testWidgets('Trip warnings, mixed text and details in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme(Brightness.light),
          home: Directionality(
            textDirection: direction,
            child: TripsPage(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('OVER CAPACITY'), findsOneWidget);
      expect(find.textContaining('REVIEW FLIGHT'), findsOneWidget);
      await tester.tap(find.textContaining('שדה Airport'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Over capacity. Review'), findsOneWidget);
      expect(find.textContaining('trip schedule is unchanged'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }
  testWidgets('draft survives realtime and stale conflict', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripEditorPage(controller: controller, trip: repo.rows.single),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Manager draft');
    repo.changes.add(RepositorySignal.changed);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.text('Manager draft'), findsOneWidget);
    repo.writeFailure = CloudFailureKind.conflict;
    await tester.scrollUntilVisible(
      find.text('Save trip'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save trip'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(controller.state.failure, CloudFailureKind.conflict);
    await tester.scrollUntilVisible(
      find.textContaining('draft is preserved'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('draft is preserved'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save trip'))
          .onPressed,
      null,
    );
  });
}
