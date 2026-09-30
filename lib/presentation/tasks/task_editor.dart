import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/tasks_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/task.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../../domain/repositories/event_repository.dart';
import '../design_system.dart';
import 'task_labels.dart';
import 'task_due_field.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.controller, this.base});
  final TasksController controller;
  final EventTask? base;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();
  late final _title = TextEditingController(text: widget.base?.input.title);
  late final _description = TextEditingController(
    text: widget.base?.input.description,
  );
  late final _notes = TextEditingController(text: widget.base?.input.notes);
  late String? _assignee = widget.base?.input.assigneeId;
  late TaskPriority? _priority = widget.base?.input.priority;
  late DateTime? _due = widget.base?.input.dueDateUtc;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? optional(String s) => s.isEmpty ? null : s;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TasksController, TasksState>(
    bloc: widget.controller,
    builder: (context, s) => Scaffold(
      appBar: AppBar(
        title: Text(widget.base == null ? 'New task' : 'Edit task'),
      ),
      body: SafeArea(
        child: s.failure == CloudFailureKind.unauthorized
            ? const Center(child: Text('Task access is no longer available.'))
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpace.l),
                  children: [
                    TasksFeedback(state: s, retry: widget.controller.refresh),
                    TextFormField(
                      key: const ValueKey('task-title'),
                      controller: _title,
                      maxLength: 500,
                      enabled: s.canWrite,
                      decoration: const InputDecoration(
                        labelText: 'Title (required)',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a task title.'
                          : null,
                    ),
                    const SizedBox(height: AppSpace.l),
                    TextFormField(
                      controller: _description,
                      maxLength: 10000,
                      minLines: 2,
                      maxLines: 5,
                      enabled: s.canWrite,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: AppSpace.l),
                    DropdownButtonFormField<String>(
                      initialValue: _assignee,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Assignee'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        for (final a in s.assignees.where(
                          (a) => !a.isDeleted || a.id == _assignee,
                        ))
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              BidiTextFormatter.isolate(
                                '${a.label}${a.isDeleted ? ' (deleted)' : ''}',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_assignee != null &&
                            !s.assignees.any((a) => a.id == _assignee))
                          DropdownMenuItem(
                            value: _assignee,
                            child: const Text('Assignee unavailable'),
                          ),
                      ],
                      onChanged: !s.canWrite
                          ? null
                          : (v) => setState(() => _assignee = v),
                    ),
                    const SizedBox(height: AppSpace.l),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        const DropdownMenuItem<TaskPriority>(
                          value: null,
                          child: Text('Not set'),
                        ),
                        for (final p in TaskPriority.values)
                          DropdownMenuItem(
                            value: p,
                            child: Text(taskPriorityLabel(p)),
                          ),
                      ],
                      onChanged: !s.canWrite
                          ? null
                          : (v) => setState(() => _priority = v),
                    ),
                    const SizedBox(height: AppSpace.l),
                    TaskDueField(
                      value: _due,
                      enabled: s.canWrite,
                      onChanged: (v) => setState(() => _due = v),
                    ),
                    const Text(
                      'Date and time use this phone’s local timezone.',
                    ),
                    const SizedBox(height: AppSpace.l),
                    TextFormField(
                      controller: _notes,
                      maxLength: 10000,
                      minLines: 2,
                      maxLines: 5,
                      enabled: s.canWrite,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    if (_error != null) Text(_error!),
                    FilledButton(
                      onPressed: !s.canWrite
                          ? null
                          : () async {
                              if (!_form.currentState!.validate()) return;
                              final input = TaskInput(
                                title: _title.text,
                                description: optional(_description.text),
                                notes: optional(_notes.text),
                                assigneeId: _assignee,
                                priority: _priority,
                                dueDateUtc: _due,
                              );
                              try {
                                input.validate();
                              } on FormatException catch (e) {
                                setState(() => _error = e.message);
                                return;
                              }
                              final ok = await widget.controller.saveTask(
                                input,
                                requestId: _requestId,
                                base: widget.base,
                              );
                              if (context.mounted && ok) Navigator.pop(context);
                            },
                      child: Text(
                        s.save == SaveStatus.saving ? 'Saving...' : 'Save task',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
