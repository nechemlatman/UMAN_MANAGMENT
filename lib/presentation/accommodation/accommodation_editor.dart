import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/accommodation_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/value_objects/civil_date.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

import 'accommodation_feedback.dart';
import '../forms/optional_civil_date.dart';

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
  SleepingPlaceType? _type;
  CivilDate? _start, _end;
  bool _active = false, _locked = false, _conflicted = false;
  String? _parent, _person, _error;
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
    final i = widget.base?.input;
    _parent = widget.parentId;
    _person = widget.personId;
    _status = 'ACTIVE';
    _type = null;
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
        _active = b?.isActive ?? false;
        fields = {
          'Label': b?.label,
          'Custom type name': b?.customTypeName,
          'Position notes': b?.positionNotes,
        };
      case AccommodationKind.assignment:
        final a = i as AccommodationAssignmentInput?;
        _parent = a?.sleepingPlaceId ?? _parent;
        _person = a?.personId ?? _person;
        _status = a?.status.name.toUpperCase() ?? 'DRAFT';
        _start = a?.startDate;
        _end = a?.endDate;
        _locked = a?.isLocked ?? false;
        fields = {'Notes': a?.notes};
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

  AccommodationInput _input() => switch (widget.kind) {
    AccommodationKind.apartment => ApartmentInput(
      name: _text['Name']!.text.trim(),
      address: _optional('Address'),
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
      apartmentId: _parent,
      nameOrNumber: _text['Name or number']!.text.trim(),
      floor: _optional('Floor'),
      description: _optional('Description'),
      notes: _optional('Notes'),
    ),
    AccommodationKind.sleepingPlace => SleepingPlaceInput(
      roomId: _parent,
      label: _optional('Label'),
      type: _type,
      customTypeName: _optional('Custom type name'),
      positionNotes: _optional('Position notes'),
      isActive: _active,
    ),
    AccommodationKind.assignment => AccommodationAssignmentInput(
      sleepingPlaceId: _parent,
      personId: _person,
      startDate: _start,
      endDate: _end,
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
          '${apartment.input.name} / ${room.input.nameOrNumber} / ${bed.input.label ?? 'New sleeping place'}${bed.input.isActive ? '' : ' (inactive)'}';
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
        items: [
          if (label != 'Status')
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Not selected'),
            ),
          ...items.entries.map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(
                accommodationBidi(e.value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: changed,
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
            '${widget.base == null ? 'New' : 'Edit'} ${accommodationKindLabel(widget.kind)}',
          ),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              AccommodationFeedback(state: s),
              if (widget.personId != null && widget.base == null)
                accommodationWarning(
                  context,
                  'Moving creates a new assignment. Return to the previous assignment and explicitly end or cancel it; its history is preserved.',
                ),
              if (widget.kind == AccommodationKind.assignment) ...[
                _select(
                  'Sleeping place',
                  _parent,
                  _bedOptions(s.data),
                  enabled && !(widget.base?.hasBeenOperational ?? false)
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
                  enabled &&
                          !(widget.base?.hasBeenOperational ?? false) &&
                          widget.personId == null
                      ? (v) => setState(() => _person = v)
                      : null,
                ),
                const Text(
                  'Check-in includes the first night; checkout excludes that night. Same-day turnover is allowed.',
                ),
                if (overlapping)
                  accommodationWarning(
                    context,
                    'ACCOMMODATION_OVERLAP — these dates intersect another assignment. Saving preserves both assignments and the warning.',
                  ),
              ],
              if (widget.kind == AccommodationKind.room)
                _select(
                  'Apartment',
                  _parent,
                  {
                    for (final a in s.data.apartments.where(
                      (a) => !a.isDeleted,
                    ))
                      a.id: a.input.name,
                  },
                  enabled &&
                          (widget.base?.input as RoomInput?)?.apartmentId ==
                              null
                      ? (v) => setState(() => _parent = v)
                      : null,
                ),
              if (widget.kind == AccommodationKind.sleepingPlace)
                _select(
                  'Room',
                  _parent,
                  {
                    for (final r in s.data.rooms.where((r) => !r.isDeleted))
                      r.id: r.input.nameOrNumber,
                  },
                  enabled &&
                          (widget.base?.input as SleepingPlaceInput?)?.roomId ==
                              null
                      ? (v) => setState(() => _parent = v)
                      : null,
                ),
              if (widget.kind == AccommodationKind.assignment)
                OptionalCivilDateRangeField(
                  start: _start,
                  end: _end,
                  enabled: enabled,
                  onChanged: (start, end) => setState(() {
                    _start = start;
                    _end = end;
                  }),
                ),
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
                        ['Name', 'Name or number'].contains(e.key) &&
                            (v?.trim().isEmpty ?? true)
                        ? 'Enter ${e.key.toLowerCase()} to identify this record.'
                        : null,
                  ),
                ),
              if (widget.kind == AccommodationKind.apartment ||
                  widget.kind == AccommodationKind.assignment)
                _select('Status', _status, {
                  for (final v
                      in widget.kind == AccommodationKind.apartment
                          ? ApartmentStatus.values.map(
                              (v) => v.name.toUpperCase(),
                            )
                          : AccommodationStatus.values.map(
                              (v) => v.name.toUpperCase(),
                            ))
                    v: v,
                }, enabled ? (v) => setState(() => _status = v!) : null),
              if (widget.kind == AccommodationKind.sleepingPlace) ...[
                _select(
                  'Type',
                  _type?.code,
                  {for (final t in SleepingPlaceType.values) t.code: t.code},
                  enabled
                      ? (v) => setState(
                          () => _type = v == null
                              ? null
                              : SleepingPlaceType.values.firstWhere(
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
              if (_error != null) accommodationWarning(context, _error!),
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
