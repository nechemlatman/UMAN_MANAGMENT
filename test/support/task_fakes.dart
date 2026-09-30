import 'dart:async';
import 'package:uman_event_manager/domain/entities/task.dart';
import 'package:uman_event_manager/domain/repositories/tasks_repository.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';

const taskEvent = '11111111-1111-4111-8111-111111111111';
const taskId = '88888888-8888-4888-8888-888888888888';
EventTask taskSample({
  int version = 1,
  String title = 'Arrange arrival',
  bool deleted = false,
  TaskStatus status = TaskStatus.newTask,
  TaskInput? input,
}) => EventTask(
  id: taskId,
  eventId: taskEvent,
  input: input ?? TaskInput(title: title),
  status: status,
  version: version,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  createdBy: taskEvent,
  updatedBy: taskEvent,
  isDeleted: deleted,
  deletedAtUtc: deleted ? DateTime.utc(2026) : null,
);

class FakeTasksRepository implements TasksRepository {
  @override
  String get eventId => taskEvent;
  final changes = StreamController<RepositorySignal>.broadcast();
  List<EventTask> rows = [taskSample()];
  List<TaskAssignee> people = [];
  CloudFailureKind? readFailure, writeFailure;
  Completer<void>? gate;
  int reads = 0, writes = 0;
  bool disposed = false;
  TaskInput? saved;
  @override
  Stream<RepositorySignal> get signals => changes.stream;
  @override
  Future<List<EventTask>> listTasks({
    String query = '',
    bool deleted = false,
  }) async {
    reads++;
    final wait = gate;
    gate = null;
    if (wait != null) await wait.future;
    if (readFailure != null) throw CloudFailure(readFailure!);
    return rows
        .where(
          (t) =>
              t.isDeleted == deleted &&
              t.input.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<EventTask?> readTask(String id) async =>
      rows.where((t) => t.id == id).firstOrNull;
  @override
  Future<List<TaskAssignee>> assignees() async => people;
  void check(EventTask? base) {
    if (writeFailure != null) throw CloudFailure(writeFailure!);
    if (base != null && base.version != rows.single.version) {
      throw const CloudFailure(CloudFailureKind.conflict);
    }
    writes++;
  }

  @override
  Future<String> saveTask(
    TaskInput input, {
    required String requestId,
    EventTask? base,
  }) async {
    check(base);
    saved = input;
    rows = [
      taskSample(
        input: input,
        version: (base?.version ?? 0) + 1,
        status: base?.status ?? TaskStatus.newTask,
      ),
    ];
    return taskId;
  }

  @override
  Future<void> transition(EventTask base, TaskStatus status) async {
    check(base);
    rows = [
      taskSample(input: base.input, version: base.version + 1, status: status),
    ];
  }

  @override
  Future<void> setDeleted(EventTask base, bool deleted) async {
    check(base);
    rows = [
      taskSample(
        input: base.input,
        version: base.version + 1,
        status: base.status,
        deleted: deleted,
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await changes.close();
  }
}
