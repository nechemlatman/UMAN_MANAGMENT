import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/accommodation_controller.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/value_objects/civil_date.dart';
import '../design_system.dart';
import '../forms/optional_civil_date.dart';

import 'accommodation_editor.dart';
import 'accommodation_feedback.dart';
export 'accommodation_editor.dart';

Future<void> _editor(
  BuildContext context,
  AccommodationController controller,
  AccommodationKind kind, {
  AccommodationRecord? base,
  String? parentId,
  String? personId,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AccommodationEditorPage(
      controller: controller,
      kind: kind,
      base: base,
      parentId: parentId,
      personId: personId,
    ),
  ),
);
Future<void> _deleted(
  BuildContext context,
  AccommodationController controller,
  AccommodationRecord row,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        '${row.isDeleted ? 'Restore' : 'Delete'} ${accommodationKindLabel(row.input.kind)}?',
      ),
      content: Text(
        row.isDeleted
            ? 'This restores only this record. Related records keep their own status.'
            : 'The record remains in history. Children and assignments are preserved and can be restored or managed explicitly.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(row.isDeleted ? 'Restore' : 'Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) await controller.setDeleted(row, !row.isDeleted);
}

Widget _actions(
  BuildContext context,
  AccommodationController controller,
  AccommodationState s,
  AccommodationRecord row,
) => Wrap(
  spacing: AppSpace.s,
  children: [
    if (!row.isDeleted)
      TextButton(
        onPressed: s.canWrite
            ? () => _editor(context, controller, row.input.kind, base: row)
            : null,
        child: Text('Edit ${accommodationKindLabel(row.input.kind)}'),
      ),
    TextButton(
      onPressed: s.canWrite ? () => _deleted(context, controller, row) : null,
      child: Text(row.isDeleted ? 'Restore' : 'Delete'),
    ),
  ],
);

class ApartmentsPage extends StatefulWidget {
  const ApartmentsPage({super.key, required this.controller});
  final AccommodationController controller;
  @override
  State<ApartmentsPage> createState() => _ApartmentsPageState();
}

class _ApartmentsPageState extends State<ApartmentsPage> {
  bool _deleted = false;
  String _query = '';
  late CivilDate _night = widget.controller.events.state
      .capabilities(widget.controller.repository.eventId)
      .event!
      .startDate;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AccommodationController, AccommodationState>(
    bloc: widget.controller,
    builder: (context, s) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: s.canWrite
            ? () => _editor(
                context,
                widget.controller,
                AccommodationKind.apartment,
              )
            : null,
        icon: const Icon(Icons.add),
        label: const Text('New apartment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.l),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search apartments',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Wrap(
            spacing: AppSpace.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: OptionalCivilDateField(
                  label: 'Occupancy night',
                  value: _night,
                  allowClear: false,
                  onChanged: (value) {
                    if (value != null) setState(() => _night = value);
                  },
                ),
              ),
              FilterChip(
                label: const Text('Deleted apartments'),
                selected: _deleted,
                onSelected: (v) => setState(() => _deleted = v),
              ),
            ],
          ),
          AccommodationFeedback(state: s),
          if (s.loading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpace.l),
                children: [
                  ExpansionTile(
                    title: const Text('Drafts and unplaced records'),
                    subtitle: const Text(
                      'Save details now; complete the hierarchy later.',
                    ),
                    children: [
                      Wrap(
                        spacing: AppSpace.s,
                        children: [
                          for (final kind in [
                            AccommodationKind.room,
                            AccommodationKind.sleepingPlace,
                            AccommodationKind.assignment,
                          ])
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              onPressed: s.canWrite
                                  ? () => _editor(
                                      context,
                                      widget.controller,
                                      kind,
                                    )
                                  : null,
                              label: Text(
                                'New ${accommodationKindLabel(kind)}',
                              ),
                            ),
                        ],
                      ),
                      for (final row in <AccommodationRecord>[
                        ...s.data.rooms.where(
                          (r) => r.input.apartmentId == null,
                        ),
                        ...s.data.sleepingPlaces.where(
                          (b) => !s.data.rooms.any(
                            (r) =>
                                r.id == b.input.roomId &&
                                r.input.apartmentId != null,
                          ),
                        ),
                        ...s.data.assignments.where(
                          (a) =>
                              a.input.status == AccommodationStatus.draft ||
                              a.input.sleepingPlaceId == null ||
                              !s.data.sleepingPlaces.any(
                                (b) =>
                                    b.id == a.input.sleepingPlaceId &&
                                    s.data.rooms.any(
                                      (r) =>
                                          r.id == b.input.roomId &&
                                          r.input.apartmentId != null,
                                    ),
                              ),
                        ),
                      ].where((r) => r.isDeleted == _deleted))
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                title: Text(
                                  row.input.label ??
                                      (row.input.kind ==
                                              AccommodationKind.assignment
                                          ? 'Draft assignment'
                                          : 'New sleeping place'),
                                ),
                                subtitle: Text(
                                  accommodationKindLabel(row.input.kind),
                                ),
                              ),
                              _actions(context, widget.controller, s, row),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (!s.loading &&
                      s.failure == null &&
                      !s.data.apartments.any(
                        (a) =>
                            a.isDeleted == _deleted &&
                            '${a.input.name} ${a.input.address} ${a.input.hebrewAddress ?? ''}'
                                .toLowerCase()
                                .contains(_query),
                      ))
                    ListTile(
                      title: Text(
                        _query.isNotEmpty
                            ? 'No matching apartments'
                            : _deleted
                            ? 'No deleted apartments'
                            : 'No apartments',
                      ),
                      subtitle: Text(
                        _query.isNotEmpty
                            ? 'Try another search.'
                            : _deleted
                            ? 'Deleted apartments will appear here.'
                            : 'Add an apartment, then its rooms and sleeping places.',
                      ),
                    ),
                  for (final a in s.data.apartments.where(
                    (a) =>
                        a.isDeleted == _deleted &&
                        '${a.input.name} ${a.input.address} ${a.input.hebrewAddress ?? ''}'
                            .toLowerCase()
                            .contains(_query),
                  ))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.apartment),
                        title: Text(accommodationBidi(a.input.name)),
                        subtitle: Text(
                          '${accommodationBidi(a.input.address ?? 'Address not entered')}\n${a.input.status.name.toUpperCase()} · ${s.data.occupiedBeds(a.id, _night)} occupied sleeping places',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ApartmentDetailsPage(
                              controller: widget.controller,
                              apartmentId: a.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpace.touch + AppSpace.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ApartmentDetailsPage extends StatefulWidget {
  const ApartmentDetailsPage({
    super.key,
    required this.controller,
    required this.apartmentId,
  });
  final AccommodationController controller;
  final String apartmentId;
  @override
  State<ApartmentDetailsPage> createState() => _ApartmentDetailsPageState();
}

class _ApartmentDetailsPageState extends State<ApartmentDetailsPage> {
  bool _showDeleted = false;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AccommodationController, AccommodationState>(
    bloc: widget.controller,
    builder: (context, s) {
      final a = s.data.apartments
          .where((a) => a.id == widget.apartmentId)
          .firstOrNull;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            a == null
                ? 'Apartment unavailable'
                : accommodationBidi(a.input.name),
          ),
        ),
        body: a == null
            ? const Center(child: Text('Apartment unavailable'))
            : RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpace.l),
                  children: [
                    Text(
                      accommodationBidi(
                        a.input.address ?? 'Address not entered',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (a.input.hebrewAddress != null)
                      Text(accommodationBidi(a.input.hebrewAddress!)),
                    Text('Status: ${a.input.status.name.toUpperCase()}'),
                    for (final entry in {
                      'Floor': a.input.floor,
                      'Entry code': a.input.entryCode,
                      'Landlord': a.input.landlordName,
                      'Landlord phone': a.input.landlordPhone,
                      'Notes': a.input.notes,
                      'Total cost': a.input.totalCost,
                      'Currency': a.input.costCurrency,
                      'Cost notes': a.input.costNotes,
                    }.entries)
                      if (entry.value != null && entry.value!.isNotEmpty)
                        Text(
                          '${entry.key}: ${accommodationBidi(entry.value!)}',
                        ),
                    if (a.isDeleted)
                      accommodationWarning(
                        context,
                        'Apartment deleted. Its rooms and assignments remain in history.',
                      ),
                    if (a.input.status != ApartmentStatus.active)
                      accommodationWarning(
                        context,
                        'Apartment ${a.input.status.name}. Review its assignments explicitly.',
                      ),
                    AccommodationFeedback(state: s),
                    _actions(context, widget.controller, s, a),
                    Wrap(
                      spacing: AppSpace.s,
                      children: [
                        FilledButton.icon(
                          onPressed: s.canWrite && !a.isDeleted
                              ? () => _editor(
                                  context,
                                  widget.controller,
                                  AccommodationKind.room,
                                  parentId: a.id,
                                )
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Add room'),
                        ),
                        FilterChip(
                          label: const Text('Show deleted records'),
                          selected: _showDeleted,
                          onSelected: (v) => setState(() => _showDeleted = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.l),
                    if (!s.data.rooms.any((r) => r.input.apartmentId == a.id))
                      const Text('No rooms yet.'),
                    for (final room in s.data.rooms.where(
                      (r) =>
                          r.input.apartmentId == a.id &&
                          (_showDeleted || !r.isDeleted),
                    ))
                      Card(
                        child: ExpansionTile(
                          key: PageStorageKey(room.id),
                          title: Text(
                            accommodationBidi(room.input.nameOrNumber),
                          ),
                          subtitle: Text(
                            room.isDeleted
                                ? 'Deleted room'
                                : '${s.data.sleepingPlaces.where((b) => b.input.roomId == room.id && !b.isDeleted).length} sleeping places',
                          ),
                          childrenPadding: const EdgeInsets.all(AppSpace.m),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in {
                              'Floor': room.input.floor,
                              'Description': room.input.description,
                              'Notes': room.input.notes,
                            }.entries)
                              if (entry.value != null)
                                Text(
                                  '${entry.key}: ${accommodationBidi(entry.value!)}',
                                ),
                            if (room.isDeleted || a.isDeleted)
                              accommodationWarning(
                                context,
                                'Parent or room deleted. Existing assignments are preserved; review them.',
                              ),
                            _actions(context, widget.controller, s, room),
                            TextButton.icon(
                              onPressed:
                                  s.canWrite && !a.isDeleted && !room.isDeleted
                                  ? () => _editor(
                                      context,
                                      widget.controller,
                                      AccommodationKind.sleepingPlace,
                                      parentId: room.id,
                                    )
                                  : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Add sleeping place'),
                            ),
                            for (final bed in s.data.sleepingPlaces.where(
                              (b) =>
                                  b.input.roomId == room.id &&
                                  (_showDeleted || !b.isDeleted),
                            ))
                              ExpansionTile(
                                key: PageStorageKey(bed.id),
                                leading: const Icon(Icons.bed),
                                title: Text(
                                  accommodationBidi(
                                    bed.input.label ?? 'New sleeping place',
                                  ),
                                ),
                                subtitle: Text(
                                  '${bed.input.type == SleepingPlaceType.custom ? accommodationBidi(bed.input.customTypeName ?? '') : bed.input.type?.code ?? 'Type not selected'}${bed.isDeleted
                                      ? ' · DELETED'
                                      : !bed.input.isActive
                                      ? ' · INACTIVE'
                                      : ''}',
                                ),
                                childrenPadding: const EdgeInsets.all(
                                  AppSpace.m,
                                ),
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (bed.input.positionNotes != null)
                                    Text(
                                      accommodationBidi(
                                        bed.input.positionNotes!,
                                      ),
                                    ),
                                  if (bed.isDeleted || !bed.input.isActive)
                                    accommodationWarning(
                                      context,
                                      'Sleeping place ${bed.isDeleted ? 'deleted' : 'inactive'}. Assignments have not been changed.',
                                    ),
                                  _actions(context, widget.controller, s, bed),
                                  TextButton.icon(
                                    onPressed:
                                        s.canWrite &&
                                            !a.isDeleted &&
                                            !room.isDeleted &&
                                            !bed.isDeleted
                                        ? () => _editor(
                                            context,
                                            widget.controller,
                                            AccommodationKind.assignment,
                                            parentId: bed.id,
                                          )
                                        : null,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Add assignment'),
                                  ),
                                  for (final assignment
                                      in s.data.assignments.where(
                                        (v) =>
                                            v.input.sleepingPlaceId == bed.id &&
                                            (_showDeleted || !v.isDeleted),
                                      ))
                                    _assignment(context, s, assignment),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      );
    },
  );
  Widget _assignment(
    BuildContext context,
    AccommodationState s,
    AccommodationAssignment assignment,
  ) {
    final p = s.data.people
        .where((p) => p.id == assignment.input.personId)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              accommodationBidi(p?.label ?? 'Person unavailable'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${accommodationBidi(assignment.input.startDate?.toString() ?? 'Check-in not selected')} → ${accommodationBidi(assignment.input.endDate?.toString() ?? 'Checkout not selected')} (checkout exclusive)',
              textDirection: TextDirection.ltr,
            ),
            Text(
              '${assignment.input.status.name.toUpperCase()}${assignment.isDeleted ? ' · DELETED' : ''}',
            ),
            if (p == null || p.isDeleted)
              accommodationWarning(
                context,
                'Person unavailable or deleted. Assignment history is preserved.',
              ),
            if (s.data.hasOverlap(assignment.id))
              accommodationWarning(
                context,
                'ACCOMMODATION_OVERLAP — another assignment uses this sleeping place on intersecting nights. Review dates or cancel explicitly.',
              ),
            if (assignment.input.isLocked)
              const Text('Manager override / locked'),
            if (assignment.input.notes != null)
              Text(accommodationBidi(assignment.input.notes!)),
            _actions(context, widget.controller, s, assignment),
            if (!assignment.isDeleted)
              TextButton(
                onPressed: s.canWrite
                    ? () => _editor(
                        context,
                        widget.controller,
                        AccommodationKind.assignment,
                        personId: assignment.input.personId,
                      )
                    : null,
                child: const Text('Move person — create new assignment'),
              ),
          ],
        ),
      ),
    );
  }
}
