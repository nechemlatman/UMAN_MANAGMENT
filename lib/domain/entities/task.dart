import '../value_objects/uuid_v4.dart';

enum TaskPriority {
  critical('CRITICAL'),
  high('HIGH'),
  medium('MEDIUM'),
  low('LOW');

  const TaskPriority(this.code);
  final String code;
}

enum TaskStatus {
  newTask('NEW'),
  inProgress('IN_PROGRESS'),
  waiting('WAITING'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TaskStatus(this.code);
  final String code;
  bool get terminal => this == completed || this == cancelled;
  List<TaskStatus> get transitions => switch (this) {
    newTask => [inProgress, cancelled],
    inProgress => [waiting, completed, cancelled],
    waiting => [inProgress, cancelled],
    completed || cancelled => [newTask, inProgress, waiting],
  };
}

/// Source fields only. Lifecycle transitions are separate explicit commands.
class TaskInput {
  const TaskInput({
    required this.title,
    this.description,
    this.assigneeId,
    this.priority,
    this.dueDateUtc,
    this.notes,
  });
  final String title;
  final String? description, assigneeId, notes;
  final TaskPriority? priority;
  final DateTime? dueDateUtc;
  void validate() {
    if (title.trim().isEmpty || title.runes.length > 500) {
      throw const FormatException('Enter a title of at most 500 characters.');
    }
    for (final value in [description, notes]) {
      if (value != null && value.runes.length > 10000) {
        throw const FormatException(
          'Description and notes allow at most 10000 characters.',
        );
      }
    }
    if (assigneeId != null && !UuidV4.isValid(assigneeId!)) {
      throw const FormatException('Invalid assignee.');
    }
    if (dueDateUtc != null &&
        (dueDateUtc!.year < 1 || dueDateUtc!.year > 9999)) {
      throw const FormatException(
        'Due date is outside the supported calendar.',
      );
    }
  }
}

class EventTask {
  const EventTask({
    required this.id,
    required this.eventId,
    required this.input,
    required this.status,
    required this.version,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdBy,
    required this.updatedBy,
    this.completedAtUtc,
    this.cancelledAtUtc,
    this.isDeleted = false,
    this.deletedAtUtc,
  });
  final String id, eventId, createdBy, updatedBy;
  final TaskInput input;
  final TaskStatus status;
  final int version;
  final DateTime createdAtUtc, updatedAtUtc;
  final DateTime? completedAtUtc, cancelledAtUtc, deletedAtUtc;
  final bool isDeleted;
  bool isOverdue(DateTime now) =>
      !isDeleted &&
      !status.terminal &&
      input.dueDateUtc != null &&
      input.dueDateUtc!.isBefore(now);
}

class TaskAssignee {
  const TaskAssignee(this.id, this.label, {this.isDeleted = false});
  final String id, label;
  final bool isDeleted;
}
