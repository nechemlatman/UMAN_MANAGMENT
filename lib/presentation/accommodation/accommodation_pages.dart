import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/accommodation_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/value_objects/civil_date.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

String _b(String value) => BidiTextFormatter.isolate(value);
String _kind(AccommodationKind kind) => switch (kind) {
  AccommodationKind.apartment => 'apartment',
  AccommodationKind.room => 'room',
  AccommodationKind.sleepingPlace => 'sleeping place',
  AccommodationKind.assignment => 'assignment',
};
Widget _warning(BuildContext context, String message) => Card(
  color: Theme.of(context).colorScheme.errorContainer,
  child: Padding(
    padding: const EdgeInsets.all(AppSpace.m),
    child: Text(
      '⚠ $message',
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  ),
);

class AccommodationFeedback extends StatelessWidget {
  const AccommodationFeedback({super.key, required this.state});
  final AccommodationState state;
  @override
  Widget build(BuildContext context) {
    if (state.online && state.failure == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpace.m),
      child: Text(switch (state.failure) {
        CloudFailureKind.conflict =>
          'Record changed. Your draft is preserved. Go back and reopen the latest record before saving.',
        CloudFailureKind.unauthorized => 'Access is no longer available.',
        CloudFailureKind.invalid =>
          'Check the entered values and referenced records.',
        CloudFailureKind.unavailable =>
          'Server unavailable. Review the latest record after reconnecting before retrying an uncertain save.',
        CloudFailureKind.unknown =>
          'The operation could not be completed. Refresh and retry.',
        null =>
          'Offline. Displayed records may be stale; reconnect before editing.',
      }),
    );
  }
}

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
        '${row.isDeleted ? 'Restore' : 'Delete'} ${_kind(row.input.kind)}?',
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
        child: Text('Edit ${_kind(row.input.kind)}'),
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
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text('Occupancy night: ${_b(_night.toString())}'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(
                      _night.year,
                      _night.month,
                      _night.day,
                    ),
                    firstDate: DateTime(1),
                    lastDate: DateTime(9999, 12, 31),
                  );
                  if (date != null && mounted) {
                    setState(
                      () => _night = CivilDate(date.year, date.month, date.day),
                    );
                  }
                },
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
                padding: const EdgeInsets.all(AppSpace.l),
                children: [
                  if (!s.data.apartments.any((a) => a.isDeleted == _deleted))
                    const ListTile(
                      title: Text('No apartments'),
                      subtitle: Text(
                        'Add an apartment, then its rooms and sleeping places.',
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
                        title: Text(_b(a.input.name)),
                        subtitle: Text(
                          '${_b(a.input.address)}\n${a.input.status.name.toUpperCase()} · ${s.data.occupiedBeds(a.id, _night)} occupied sleeping places',
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
          title: Text(a == null ? 'Apartment unavailable' : _b(a.input.name)),
        ),
        body: a == null
            ? const Center(child: Text('Apartment unavailable'))
            : RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpace.l),
                  children: [
                    Text(
                      _b(a.input.address),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (a.input.hebrewAddress != null)
                      Text(_b(a.input.hebrewAddress!)),
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
                        Text('${entry.key}: ${_b(entry.value!)}'),
                    if (a.isDeleted)
                      _warning(
                        context,
                        'Apartment deleted. Its rooms and assignments remain in history.',
                      ),
                    if (a.input.status != ApartmentStatus.active)
                      _warning(
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
                          title: Text(_b(room.input.nameOrNumber)),
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
                                Text('${entry.key}: ${_b(entry.value!)}'),
                            if (room.isDeleted || a.isDeleted)
                              _warning(
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
                                title: Text(_b(bed.input.label)),
                                subtitle: Text(
                                  '${bed.input.type == SleepingPlaceType.custom ? _b(bed.input.customTypeName ?? '') : bed.input.type.code}${bed.isDeleted
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
                                    Text(_b(bed.input.positionNotes!)),
                                  if (bed.isDeleted || !bed.input.isActive)
                                    _warning(
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
              _b(p?.label ?? 'Person unavailable'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${_b(assignment.input.startDate.toString())} → ${_b(assignment.input.endDate.toString())} (checkout exclusive)',
              textDirection: TextDirection.ltr,
            ),
            Text(
              '${assignment.input.status.name.toUpperCase()}${assignment.isDeleted ? ' · DELETED' : ''}',
            ),
            if (p == null || p.isDeleted)
              _warning(
                context,
                'Person unavailable or deleted. Assignment history is preserved.',
              ),
            if (s.data.hasOverlap(assignment.id))
              _warning(
                context,
                'ACCOMMODATION_OVERLAP — another assignment uses this sleeping place on intersecting nights. Review dates or cancel explicitly.',
              ),
            if (assignment.input.isLocked)
              const Text('Manager override / locked'),
            if (assignment.input.notes != null)
              Text(_b(assignment.input.notes!)),
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

class AccommodationEditorPage extends StatefulWidget {
  const AccommodationEditorPage({
    super.key,
    required this.controller,
    required this.kind,
    this.base,
    this.parentId,
    this.personId,
  });
  final AccommodationController controller;
  final AccommodationKind kind;
  final AccommodationRecord? base;
  final String? parentId, personId;
  @override
  State<AccommodationEditorPage> createState() => _AccommodationEditorState();
}

class _AccommodationEditorState extends State<AccommodationEditorPage> {
  final _form = GlobalKey<FormState>();
  final _request = UuidV4.generate();
  late final Map<String, TextEditingController> _text;
  late String _status;
  late SleepingPlaceType _type;
  bool _active = true, _locked = false, _conflicted = false;
  String? _parent, _person, _error;
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
    final i = widget.base?.input;
    _parent = widget.parentId;
    _person = widget.personId;
    _status = 'ACTIVE';
    _type = SleepingPlaceType.regularBed;
    Map<String, String?> fields;
    switch (widget.kind) {
      case AccommodationKind.apartment:
        final a = i as ApartmentInput?;
        _status = a?.status.name.toUpperCase() ?? 'ACTIVE';
        fields = {
          'Name': a?.name,
          'Address': a?.address,
          'Hebrew address': a?.hebrewAddress,
          'Floor': a?.floor,
          'Entry code': a?.entryCode,
          'Landlord name': a?.landlordName,
          'Landlord phone': a?.landlordPhone,
          'Notes': a?.notes,
          'Total cost': a?.totalCost,
          'Currency': a?.costCurrency,
          'Cost notes': a?.costNotes,
        };
      case AccommodationKind.room:
        final r = i as RoomInput?;
        _parent = r?.apartmentId ?? _parent;
        fields = {
          'Name or number': r?.nameOrNumber,
          'Floor': r?.floor,
          'Description': r?.description,
          'Notes': r?.notes,
        };
      case AccommodationKind.sleepingPlace:
        final b = i as SleepingPlaceInput?;
        _parent = b?.roomId ?? _parent;
        _type = b?.type ?? _type;
        _active = b?.isActive ?? true;
        fields = {
          'Label': b?.label,
          'Custom type name': b?.customTypeName,
          'Position notes': b?.positionNotes,
        };
      case AccommodationKind.assignment:
        final a = i as AccommodationAssignmentInput?;
        _parent = a?.sleepingPlaceId ?? _parent;
        _person = a?.personId ?? _person;
        _status = a?.status.name.toUpperCase() ?? 'ACTIVE';
        _locked = a?.isLocked ?? false;
        fields = {
          'Check-in date': a?.startDate.toString(),
          'Checkout date': a?.endDate.toString(),
          'Notes': a?.notes,
        };
    }
    _text = {
      for (final e in fields.entries)
        e.key: TextEditingController(text: e.value),
    };
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(String label) {
    final v = _text[label]!.text.trim();
    return v.isEmpty ? null : v;
  }

  CivilDate _date(String key) {
    try {
      return CivilDate.parse(_text[key]!.text.trim());
    } on ArgumentError {
      throw const FormatException('Enter a valid calendar date (YYYY-MM-DD).');
    }
  }

  AccommodationInput _input() => switch (widget.kind) {
    AccommodationKind.apartment => ApartmentInput(
      name: _text['Name']!.text.trim(),
      address: _text['Address']!.text.trim(),
      hebrewAddress: _optional('Hebrew address'),
      floor: _optional('Floor'),
      entryCode: _optional('Entry code'),
      landlordName: _optional('Landlord name'),
      landlordPhone: _optional('Landlord phone'),
      notes: _optional('Notes'),
      status: ApartmentStatus.values.byName(_status.toLowerCase()),
      totalCost: _optional('Total cost'),
      costCurrency: _optional('Currency')?.toUpperCase(),
      costNotes: _optional('Cost notes'),
    ),
    AccommodationKind.room => RoomInput(
      apartmentId: _parent ?? '',
      nameOrNumber: _text['Name or number']!.text.trim(),
      floor: _optional('Floor'),
      description: _optional('Description'),
      notes: _optional('Notes'),
    ),
    AccommodationKind.sleepingPlace => SleepingPlaceInput(
      roomId: _parent ?? '',
      label: _text['Label']!.text.trim(),
      type: _type,
      customTypeName: _optional('Custom type name'),
      positionNotes: _optional('Position notes'),
      isActive: _active,
    ),
    AccommodationKind.assignment => AccommodationAssignmentInput(
      sleepingPlaceId: _parent ?? '',
      personId: _person ?? '',
      startDate: _date('Check-in date'),
      endDate: _date('Checkout date'),
      status: AccommodationStatus.values.byName(_status.toLowerCase()),
      notes: _optional('Notes'),
      isLocked: _locked,
    ),
  };
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      final input = _input();
      input.validate();
      setState(() => _error = null);
      final ok = await widget.controller.save(
        input,
        requestId: _request,
        base: widget.base,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else if (widget.controller.state.save == SaveStatus.conflict) {
        setState(() => _conflicted = true);
      }
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Map<String, String> _bedOptions(AccommodationSnapshot data) {
    final result = <String, String>{};
    for (final bed in data.sleepingPlaces) {
      final room = data.rooms
          .where((r) => r.id == bed.input.roomId)
          .firstOrNull;
      final apartment = data.apartments
          .where((a) => a.id == room?.input.apartmentId)
          .firstOrNull;
      if (bed.isDeleted ||
          room == null ||
          room.isDeleted ||
          apartment == null ||
          apartment.isDeleted) {
        continue;
      }
      result[bed.id] =
          '${apartment.input.name} / ${room.input.nameOrNumber} / ${bed.input.label}${bed.input.isActive ? '' : ' (inactive)'}';
    }
    return result;
  }

  Widget _select(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?>? changed,
  ) {
    final items = {
      ...options,
      if (value != null && !options.containsKey(value))
        value: 'Unavailable — preserved selection',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.l),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(_b(e.value), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: changed,
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AccommodationController, AccommodationState>(
    bloc: widget.controller,
    builder: (context, s) {
      final enabled =
          s.canWrite && !_conflicted && s.save != SaveStatus.conflict;
      if (s.failure == CloudFailureKind.unauthorized) {
        return Scaffold(
          appBar: AppBar(title: const Text('Accommodation unavailable')),
          body: const Center(child: Text('Access is no longer available.')),
        );
      }
      AccommodationAssignmentInput? preview;
      if (widget.kind == AccommodationKind.assignment) {
        try {
          preview = _input() as AccommodationAssignmentInput;
        } on FormatException {
          /* Incomplete dates are normal while typing. */
        }
      }
      final overlapping =
          preview != null &&
          s.data.assignments.any(
            (a) =>
                a.id != widget.base?.id &&
                !a.isDeleted &&
                preview!.overlaps(a.input),
          );
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.base == null ? 'New' : 'Edit'} ${_kind(widget.kind)}',
          ),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              AccommodationFeedback(state: s),
              if (widget.personId != null && widget.base == null)
                _warning(
                  context,
                  'Moving creates a new assignment. Return to the previous assignment and explicitly end or cancel it; its history is preserved.',
                ),
              if (widget.kind == AccommodationKind.assignment) ...[
                _select(
                  'Sleeping place',
                  _parent,
                  _bedOptions(s.data),
                  enabled && widget.base == null
                      ? (v) => setState(() => _parent = v)
                      : null,
                ),
                _select(
                  'Person',
                  _person,
                  {
                    for (final p in s.data.people.where((p) => !p.isDeleted))
                      p.id: p.label,
                  },
                  enabled && widget.base == null && widget.personId == null
                      ? (v) => setState(() => _person = v)
                      : null,
                ),
                const Text(
                  'Check-in includes the first night; checkout excludes that night. Same-day turnover is allowed.',
                ),
                if (overlapping)
                  _warning(
                    context,
                    'ACCOMMODATION_OVERLAP — these dates intersect another assignment. Saving preserves both assignments and the warning.',
                  ),
              ],
              for (final e in _text.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.l),
                  child: TextFormField(
                    controller: e.value,
                    enabled: s.save != SaveStatus.saving,
                    onChanged: (_) => setState(() {}),
                    textDirection:
                        [
                          'Landlord phone',
                          'Entry code',
                          'Total cost',
                          'Currency',
                          'Check-in date',
                          'Checkout date',
                        ].contains(e.key)
                        ? TextDirection.ltr
                        : null,
                    keyboardType: e.key == 'Total cost'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : null,
                    maxLines: e.key.contains('notes') || e.key == 'Notes'
                        ? 3
                        : 1,
                    decoration: InputDecoration(
                      labelText: e.key,
                      helperText: e.key.contains('date') ? 'YYYY-MM-DD' : null,
                    ),
                    validator: (v) =>
                        [
                              'Name',
                              'Address',
                              'Name or number',
                              'Label',
                              'Check-in date',
                              'Checkout date',
                            ].contains(e.key) &&
                            (v?.trim().isEmpty ?? true)
                        ? 'Required'
                        : null,
                  ),
                ),
              if (widget.kind == AccommodationKind.apartment ||
                  widget.kind == AccommodationKind.assignment)
                _select('Status', _status, {
                  for (final v
                      in widget.kind == AccommodationKind.apartment
                          ? ['ACTIVE', 'UNAVAILABLE', 'CLOSED']
                          : ['ACTIVE', 'TEMPORARY', 'CANCELLED'])
                    v: v,
                }, enabled ? (v) => setState(() => _status = v!) : null),
              if (widget.kind == AccommodationKind.sleepingPlace) ...[
                _select(
                  'Type',
                  _type.code,
                  {for (final t in SleepingPlaceType.values) t.code: t.code},
                  enabled
                      ? (v) => setState(
                          () => _type = SleepingPlaceType.values.firstWhere(
                            (t) => t.code == v,
                          ),
                        )
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Active sleeping place'),
                  value: _active,
                  onChanged: enabled
                      ? (v) => setState(() => _active = v)
                      : null,
                ),
              ],
              if (widget.kind == AccommodationKind.assignment)
                SwitchListTile(
                  title: const Text('Manager override / locked'),
                  subtitle: const Text(
                    'Requires a note. Overlap warnings remain visible.',
                  ),
                  value: _locked,
                  onChanged: enabled
                      ? (v) => setState(() => _locked = v)
                      : null,
                ),
              if (_error != null) _warning(context, _error!),
              FilledButton(
                onPressed: enabled ? _save : null,
                child: Text(s.save == SaveStatus.saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
