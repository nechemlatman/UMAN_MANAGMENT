import 'package:uman_event_manager/presentation/events/event_shell.dart';
import 'support/people_fakes.dart';
import 'support/flights_fakes.dart';
import 'support/transport_fakes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/tasks_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/entities/task.dart';
import 'package:uman_event_manager/presentation/design_system.dart';
import 'package:uman_event_manager/presentation/tasks/tasks_page.dart';
import 'package:uman_event_manager/presentation/tasks/task_editor.dart';
import 'package:uman_event_manager/presentation/tasks/task_due_field.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/task_fakes.dart';

void main() {
  late FakeTasksRepository repo;
  late EventController events;
  late TasksController controller;
  setUp(() async {
    events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    repo = FakeTasksRepository();
    controller = TasksController(repo, events);
    await controller.start();
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  for (final direction in TextDirection.values) {
    for (final brightness in Brightness.values) {
      testWidgets('Phone Tasks create and lifecycle $direction $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme(brightness),
            builder: (context, child) =>
                Directionality(textDirection: direction, child: child!),
            home: TasksPage(controller: controller),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Arrange arrival'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('In progress'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('In progress'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(repo.rows.single.status, TaskStatus.inProgress);
        await tester.scrollUntilVisible(
          find.text('Completed'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(repo.rows.single.status, TaskStatus.completed);
        await tester.scrollUntilVisible(
          find.text('New'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('New'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Reopen this task explicitly'),
          findsOneWidget,
        );
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(repo.rows.single.status, TaskStatus.newTask);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('New task'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          'משימה Task ${'long ' * 20}',
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Save task'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Save task'));
        await tester.pumpAndSettle();
        expect(repo.saved!.priority, isNull);
        expect(repo.saved!.dueDateUtc, isNull);
        expect(repo.saved!.assigneeId, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
    'Event shell exposes configured Tasks without other placeholders',
    (tester) async {
      final shellRepo = FakeTasksRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: EventShell(
            events: events,
            eventId: taskEvent,
            peopleFactory: (_) => FakePeopleRepository(),
            flightsFactory: (_) => FakeFlightsRepository(),
            transportFactory: (_) => FakeTransportRepository(),
            tasksFactory: (_) => shellRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Finance'), findsNothing);
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('New task'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      expect(shellRepo.disposed, true);
    },
  );
  testWidgets(
    'Empty and failed list offers recovery; filters show no matches',
    (tester) async {
      repo.rows = [];
      await controller.refresh();
      await tester.pumpWidget(
        MaterialApp(home: TasksPage(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No tasks yet. Add the first task.'), findsOneWidget);
      repo.readFailure = CloudFailureKind.unavailable;
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Refresh / Retry'), findsOneWidget);
      expect(find.text('New task'), findsNothing);
      repo.readFailure = null;
      repo.rows = [taskSample()];
      await tester.tap(find.text('Refresh / Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Arrange arrival'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'absent');
      await tester.pumpAndSettle(const Duration(milliseconds: 350));
      expect(find.textContaining('No matching tasks'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Draft survives conflict and access revocation hides fields', (
    tester,
  ) async {
    final base = repo.rows.single;
    await tester.pumpWidget(
      MaterialApp(
        home: TaskEditor(controller: controller, base: base),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title')),
      'My unsaved task',
    );
    repo.rows = [taskSample(version: 2, title: 'Remote edit')];
    repo.changes.add(RepositorySignal.changed);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save task'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await controller.stream
          .firstWhere((s) => s.save == SaveStatus.conflict)
          .timeout(const Duration(seconds: 3));
    });
    await tester.pumpAndSettle();
    expect(controller.state.failure, CloudFailureKind.conflict);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('task-title')))
          .controller!
          .text,
      'My unsaved task',
    );
    repo.readFailure = CloudFailureKind.unauthorized;
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Calendar cancellation preserves timestamp; clearing is explicit',
    (tester) async {
      DateTime? value = DateTime.utc(2026, 9, 30, 10);
      final original = value;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TaskDueField(
                value: value,
                enabled: true,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(value, original);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(value, original);
      await tester.tap(find.text('Clear due date'));
      await tester.pumpAndSettle();
      expect(value, isNull);
    },
  );
}
