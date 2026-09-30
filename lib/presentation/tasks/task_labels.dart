import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/event_repository.dart';
import '../../application/tasks_controller.dart';
import '../design_system.dart';

String taskStatusLabel(TaskStatus s) => switch (s) {
  TaskStatus.newTask => 'New',
  TaskStatus.inProgress => 'In progress',
  TaskStatus.waiting => 'Waiting',
  TaskStatus.completed => 'Completed',
  TaskStatus.cancelled => 'Cancelled',
};
String taskPriorityLabel(TaskPriority? p) => switch (p) {
  null => 'Not set',
  TaskPriority.critical => 'Critical',
  TaskPriority.high => 'High',
  TaskPriority.medium => 'Medium',
  TaskPriority.low => 'Low',
};
String taskDate(BuildContext context, DateTime? value) {
  if (value == null) return 'Not set';
  final local = value.toLocal();
  final labels = MaterialLocalizations.of(context);
  return '${labels.formatMediumDate(local)} ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}

String taskAssigneeLabel(TasksState s, String? id) {
  if (id == null) return 'Unassigned';
  final found = s.assignees.where((a) => a.id == id).firstOrNull;
  return found == null
      ? 'Assignee unavailable'
      : '${found.label}${found.isDeleted ? ' (deleted person)' : ''}';
}

class TasksFeedback extends StatelessWidget {
  const TasksFeedback({super.key, required this.state, required this.retry});
  final TasksState state;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    final message = switch (state.failure) {
      CloudFailureKind.unauthorized =>
        'Access is no longer available. Return to Events.',
      CloudFailureKind.conflict =>
        'This task changed. Your draft is kept. Go back and reopen the latest task before saving.',
      CloudFailureKind.invalid =>
        'Check the entered values, assignee, and selected action.',
      CloudFailureKind.unavailable =>
        'Server unavailable. Reconnect and refresh before retrying an uncertain save.',
      CloudFailureKind.unknown =>
        'Could not complete the operation. Refresh and try again.',
      null =>
        state.loading
            ? null
            : !state.online
            ? 'Offline. Reconnect before editing.'
            : !state.writable
            ? 'Event is read-only.'
            : !state.realtimeConnected
            ? 'Live updates reconnecting. Checking periodically.'
            : null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (state.failure != null &&
              state.failure != CloudFailureKind.unauthorized)
            TextButton(onPressed: retry, child: const Text('Refresh / Retry')),
        ],
      ),
    );
  }
}
