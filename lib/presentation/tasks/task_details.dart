import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/tasks_controller.dart';
import '../../domain/entities/task.dart';
import '../design_system.dart';
import 'task_editor.dart';
import 'task_labels.dart';

class TaskDetails extends StatefulWidget {
  const TaskDetails({super.key, required this.controller, required this.task});
  final TasksController controller;
  final EventTask task;
  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
    widget.controller.select(widget.task);
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TasksController, TasksState>(
    bloc: widget.controller,
    builder: (context, s) {
      final t = s.selected;
      return Scaffold(
        appBar: AppBar(title: const Text('Task details')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              TasksFeedback(state: s, retry: widget.controller.refresh),
              if (t == null)
                const Text('Task unavailable. Go back and refresh the list.')
              else ...[
                Text(
                  BidiTextFormatter.isolate(t.input.title),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.l),
                Text('Status: ${taskStatusLabel(t.status)}'),
                Text('Priority: ${taskPriorityLabel(t.input.priority)}'),
                Text(
                  'Assignee: ${BidiTextFormatter.isolate(taskAssigneeLabel(s, t.input.assigneeId))}',
                ),
                Text(
                  'Due (phone local time): ${taskDate(context, t.input.dueDateUtc)}',
                ),
                if (t.isOverdue(DateTime.now().toUtc()))
                  const Text('OVERDUE - still open'),
                if (t.completedAtUtc != null)
                  Text('Completed: ${taskDate(context, t.completedAtUtc)}'),
                if (t.cancelledAtUtc != null)
                  Text('Cancelled: ${taskDate(context, t.cancelledAtUtc)}'),
                if (t.input.description != null) ...[
                  const SizedBox(height: AppSpace.l),
                  const Text('Description'),
                  Text(BidiTextFormatter.isolate(t.input.description!)),
                ],
                if (t.input.notes != null) ...[
                  const SizedBox(height: AppSpace.l),
                  const Text('Notes'),
                  Text(BidiTextFormatter.isolate(t.input.notes!)),
                ],
                const SizedBox(height: AppSpace.l),
                if (t.isDeleted)
                  const Text(
                    'Deleted task. Restore to resume managing it; its lifecycle is preserved.',
                  ),
                Wrap(
                  spacing: AppSpace.s,
                  children: [
                    if (!t.isDeleted)
                      FilledButton(
                        onPressed: s.canWrite
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => TaskEditor(
                                    controller: widget.controller,
                                    base: t,
                                  ),
                                ),
                              )
                            : null,
                        child: const Text('Edit task'),
                      ),
                    TextButton(
                      onPressed: !s.canWrite
                          ? null
                          : () async {
                              if (await confirm(
                                t.isDeleted ? 'Restore task?' : 'Delete task?',
                                'The task remains in history. Its lifecycle and assignment are preserved.',
                              )) {
                                await widget.controller.setDeleted(
                                  t,
                                  !t.isDeleted,
                                );
                              }
                            },
                      child: Text(t.isDeleted ? 'Restore task' : 'Delete task'),
                    ),
                  ],
                ),
                if (!t.isDeleted) ...[
                  const SizedBox(height: AppSpace.l),
                  const Text('Change status'),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      for (final status
                          in t.status?.transitions ?? [TaskStatus.newTask])
                        OutlinedButton(
                          onPressed: !s.canWrite
                              ? null
                              : () async {
                                  if (await confirm(
                                    'Set ${taskStatusLabel(status)}?',
                                    t.status?.terminal == true
                                        ? 'Reopen this task explicitly. Its current completion/cancellation timestamp will clear; audit history remains.'
                                        : 'Change this task status. Other details stay unchanged.',
                                  )) {
                                    await widget.controller.transition(
                                      t,
                                      status,
                                    );
                                  }
                                },
                          child: Text(taskStatusLabel(status)),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    },
  );
}
