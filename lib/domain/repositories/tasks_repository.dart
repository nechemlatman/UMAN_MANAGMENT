import '../entities/task.dart';
import 'event_repository.dart';

abstract class TasksRepository {
  String get eventId;
  Stream<RepositorySignal> get signals;
  Future<List<EventTask>> listTasks({String query = '', bool deleted = false});
  Future<EventTask?> readTask(String id);
  Future<List<TaskAssignee>> assignees();
  Future<String> saveTask(
    TaskInput input, {
    required String requestId,
    EventTask? base,
  });
  Future<void> transition(EventTask base, TaskStatus status);
  Future<void> setDeleted(EventTask base, bool deleted);
  Future<void> dispose();
}
