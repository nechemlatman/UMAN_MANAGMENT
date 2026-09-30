import '../../domain/entities/task.dart';

Map<String, Object?> encodeTask(TaskInput input) => {
  'title': input.title,
  'description': input.description,
  'assignee_id': input.assigneeId,
  'priority': input.priority?.code,
  'due_date_utc': input.dueDateUtc?.toUtc().toIso8601String(),
  'notes': input.notes,
};
EventTask decodeTask(Map<String, dynamic> row) {
  DateTime? date(String key) =>
      row[key] == null ? null : DateTime.parse(row[key] as String).toUtc();
  return EventTask(
    id: row['id'] as String,
    eventId: row['event_id'] as String,
    input: TaskInput(
      title: row['title'] as String,
      description: row['description'] as String?,
      assigneeId: row['assignee_id'] as String?,
      notes: row['notes'] as String?,
      priority: row['priority'] == null
          ? null
          : TaskPriority.values.singleWhere((v) => v.code == row['priority']),
      dueDateUtc: date('due_date_utc'),
    ),
    status: row['status'] == null
        ? null
        : TaskStatus.values.singleWhere((v) => v.code == row['status']),
    version: (row['version'] as num).toInt(),
    createdAtUtc: date('created_at_utc')!,
    updatedAtUtc: date('updated_at_utc')!,
    createdBy: row['created_by'] as String,
    updatedBy: row['updated_by'] as String,
    completedAtUtc: date('completed_at_utc'),
    cancelledAtUtc: date('cancelled_at_utc'),
    isDeleted: row['is_deleted'] as bool,
    deletedAtUtc: date('deleted_at_utc'),
  );
}
