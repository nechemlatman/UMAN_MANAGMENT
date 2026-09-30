import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/tasks_controller.dart';
import '../design_system.dart';
import 'task_editor.dart';
import 'task_details.dart';
import 'task_labels.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.controller});
  final TasksController controller;
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  TaskFilter _filter = TaskFilter.all;
  late final Timer _clock;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TasksController, TasksState>(
    bloc: widget.controller,
    builder: (context, s) {
      final now = DateTime.now().toUtc();
      final rows = s.visible(_filter, now);
      return Scaffold(
        floatingActionButton: s.canWrite
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('New task'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TaskEditor(controller: widget.controller),
                  ),
                ),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.l),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: s.query,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Search tasks',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: widget.controller.updateQuery,
                      ),
                      Wrap(
                        spacing: AppSpace.s,
                        children: [
                          for (final filter in TaskFilter.values)
                            ChoiceChip(
                              label: Text(switch (filter) {
                                TaskFilter.all => 'All',
                                TaskFilter.open => 'Open',
                                TaskFilter.overdue => 'Overdue',
                              }),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                          FilterChip(
                            label: const Text('Deleted tasks'),
                            selected: s.deleted,
                            onSelected: (_) {
                              setState(() => _filter = TaskFilter.all);
                              widget.controller.toggleDeleted();
                            },
                          ),
                        ],
                      ),
                      TasksFeedback(state: s, retry: widget.controller.refresh),
                      if (s.loading) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
              if (!s.loading && s.failure == null && rows.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.l),
                    child: Text(
                      s.query.isNotEmpty || _filter != TaskFilter.all
                          ? 'No matching tasks. Try another search or filter.'
                          : s.deleted
                          ? 'No deleted tasks.'
                          : 'No tasks yet. Add the first task.',
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final task = rows[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpace.l,
                      vertical: AppSpace.xs,
                    ),
                    child: ListTile(
                      title: Text(BidiTextFormatter.isolate(task.input.title)),
                      subtitle: Text(
                        '${taskStatusLabel(task.status)} · ${taskPriorityLabel(task.input.priority)} priority\n'
                        '${BidiTextFormatter.isolate(taskAssigneeLabel(s, task.input.assigneeId))}\n'
                        'Due: ${taskDate(context, task.input.dueDateUtc)}${task.isOverdue(now) ? ' · OVERDUE' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TaskDetails(
                            controller: widget.controller,
                            task: task,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpace.touch + AppSpace.xxl),
              ),
            ],
          ),
        ),
      );
    },
  );
}
