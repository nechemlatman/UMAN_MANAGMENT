import 'package:flutter/material.dart';
import '../design_system.dart';
import 'task_labels.dart';

/// A timestamp changes only after both calendar and clock selections are confirmed.
class TaskDueField extends StatelessWidget {
  const TaskDueField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: Text('Due: ${taskDate(context, value)}'),
        onPressed: !enabled
            ? null
            : () async {
                final focus = value?.toLocal() ?? DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: focus,
                  firstDate: DateTime(1),
                  lastDate: DateTime(9999, 12, 31),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(focus),
                );
                if (time == null || !context.mounted) return;
                onChanged(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ).toUtc(),
                );
              },
      ),
      if (value != null)
        TextButton(
          onPressed: enabled ? () => onChanged(null) : null,
          child: const Text('Clear due date'),
        ),
    ],
  );
}
