import 'package:uman_event_manager/domain/entities/task.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/tasks_controller.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/task_fakes.dart';

void main() {
  late EventController events;
  late FakeTasksRepository repo;
  late TasksController controller;
  setUp(() async {
    events = EventController(FakeRepository(), MemoryCache());
    await events.start();
    repo = FakeTasksRepository();
    controller = TasksController(
      repo,
      events,
      pollInterval: const Duration(milliseconds: 40),
    );
    await controller.start();
  });
  tearDown(() async {
    await controller.close();
    await events.close();
  });
  test('invalidation and reconnect refresh canonical title', () async {
    repo.rows = [taskSample(title: 'Updated')];
    repo.changes.add(RepositorySignal.connected);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.state.tasks.single.input.title, 'Updated');
    expect(controller.state.realtimeConnected, true);
    repo.changes.add(RepositorySignal.disconnected);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.realtimeConnected, false);
  });
  test('periodic reconciliation repairs missed notifications', () async {
    repo.rows = [taskSample(title: 'Polled')];
    await Future<void>.delayed(const Duration(milliseconds: 65));
    expect(controller.state.tasks.single.input.title, 'Polled');
  });
  test(
    'invalidation during read reruns; disposal stops all resources',
    () async {
      final gate = Completer<void>();
      repo.gate = gate;
      final pending = controller.refresh();
      repo.changes.add(RepositorySignal.changed);
      await Future<void>.delayed(Duration.zero);
      final reads = repo.reads;
      gate.complete();
      await pending;
      expect(repo.reads, greaterThan(reads));
      await controller.close();
      final stopped = repo.reads;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repo.reads, stopped);
      expect(repo.disposed, true);
    },
  );
  for (final kind in CloudFailureKind.values) {
    test('write failure classified as ${kind.name}', () async {
      repo.writeFailure = kind;
      expect(
        await controller.saveTask(
          const TaskInput(title: 'Draft'),
          requestId: taskId,
        ),
        false,
      );
      expect(controller.state.failure, kind);
      expect(
        controller.state.save,
        kind == CloudFailureKind.conflict
            ? SaveStatus.conflict
            : SaveStatus.failed,
      );
      if (kind == CloudFailureKind.unauthorized) {
        expect(controller.state.tasks, isEmpty);
      }
    });
  }
  test('delete and restore reload visible state', () async {
    await controller.setDeleted(repo.rows.single, true);
    expect(controller.state.tasks, isEmpty);
    controller.toggleDeleted();
    await controller.refresh();
    expect(controller.state.tasks.single.isDeleted, true);
    await controller.setDeleted(repo.rows.single, false);
    expect(controller.state.tasks, isEmpty);
  });
  test('authorization read failure clears rows and options', () async {
    repo.readFailure = CloudFailureKind.unauthorized;
    await controller.refresh();
    expect(controller.state.tasks, isEmpty);
    expect(controller.state.assignees, isEmpty);
    expect(controller.state.canWrite, false);
  });
}
