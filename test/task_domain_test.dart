import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/task.dart';
import 'package:uman_event_manager/infrastructure/cloud/task_codec.dart';
import 'support/task_fakes.dart';

void main() {
  test('Title-only metadata save keeps unknown values null', () {
    const input = TaskInput(title: 'Phone landlord');
    input.validate();
    expect(encodeTask(input), {
      'title': 'Phone landlord',
      'description': null,
      'assignee_id': null,
      'priority': null,
      'due_date_utc': null,
      'notes': null,
    });
  });
  test('Domain rejects invalid identity, reference and lengths', () {
    for (final input in [
      const TaskInput(title: '  '),
      TaskInput(title: 'x' * 501),
      const TaskInput(title: 'Task', assigneeId: 'foreign'),
      TaskInput(title: 'Task', notes: 'x' * 10001),
    ]) {
      expect(input.validate, throwsFormatException);
    }
    TaskInput(title: 'א' * 500, description: 'x' * 10000).validate();
  });
  test(
    'Overdue is strictly past, open and not deleted; never edits source',
    () {
      final now = DateTime.utc(2026, 9, 30);
      final due = TaskInput(title: 'Due', dueDateUtc: now);
      expect(taskSample(input: due).isOverdue(now), false);
      expect(
        taskSample(input: due).isOverdue(now.add(const Duration(seconds: 1))),
        true,
      );
      for (final s in [TaskStatus.completed, TaskStatus.cancelled]) {
        expect(
          taskSample(
            input: due,
            status: s,
          ).isOverdue(now.add(const Duration(days: 1))),
          false,
        );
      }
      expect(
        taskSample(
          input: due,
          deleted: true,
        ).isOverdue(now.add(const Duration(days: 1))),
        false,
      );
      expect(taskSample().isOverdue(now), false);
      expect(due.dueDateUtc, now);
    },
  );
  test(
    'Lifecycle supports waiting, cancellation, and explicit terminal reopening',
    () {
      expect(TaskStatus.newTask.transitions, [
        TaskStatus.inProgress,
        TaskStatus.cancelled,
      ]);
      expect(
        TaskStatus.inProgress.transitions,
        containsAll([
          TaskStatus.waiting,
          TaskStatus.completed,
          TaskStatus.cancelled,
        ]),
      );
      expect(TaskStatus.waiting.transitions, [
        TaskStatus.inProgress,
        TaskStatus.cancelled,
      ]);
      for (final terminal in [TaskStatus.completed, TaskStatus.cancelled]) {
        expect(terminal.transitions, [
          TaskStatus.newTask,
          TaskStatus.inProgress,
          TaskStatus.waiting,
        ]);
      }
    },
  );
}
