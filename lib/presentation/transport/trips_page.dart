import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/trips_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/trip.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';
import 'transport_feedback.dart';

String _isolate(String value) => BidiTextFormatter.isolate(value);
String _route(Trip t) =>
    '${_isolate(t.input.origin)} → ${_isolate(t.input.destination)}';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key, required this.controller});
  final TripsController controller;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TripsController, TripsState>(
    bloc: controller,
    builder: (context, s) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: s.canWrite
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripEditorPage(controller: controller),
                ),
              )
            : null,
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.l),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search trips',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.updateQuery,
            ),
          ),
          SwitchListTile(
            title: const Text('Deleted trips'),
            value: s.deleted,
            onChanged: (_) => controller.toggleDeleted(),
          ),
          TransportFeedback(failure: s.failure, online: s.online),
          if (s.loading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.l),
                children: [
                  if (s.trips.isEmpty) const ListTile(title: Text('No trips')),
                  for (final t in s.trips)
                    Card(
                      child: ListTile(
                        title: Text(_route(t)),
                        subtitle: Text(
                          '${t.input.scheduledDepartureUtc.toIso8601String()}\n${t.input.status.code} · ${t.activePassengers}${t.vehicleCapacity == null ? '' : ' / ${t.vehicleCapacity}'} passengers${t.overCapacity ? ' · OVER CAPACITY' : ''}${t.flightNeedsReview ? ' · REVIEW FLIGHT' : ''}',
                        ),
                        isThreeLine: true,
                        leading: Icon(
                          t.overCapacity || t.flightNeedsReview
                              ? Icons.warning_amber
                              : Icons.route,
                        ),
                        onTap: () {
                          controller.select(t);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TripDetailsPage(controller: controller),
                            ),
                          );
                        },
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

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({super.key, required this.controller});
  final TripsController controller;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TripsController, TripsState>(
    bloc: controller,
    builder: (context, s) {
      final t = s.selected;
      return Scaffold(
        appBar: AppBar(title: const Text('Trip details')),
        body: t == null
            ? const Center(child: Text('Trip unavailable'))
            : ListView(
                padding: const EdgeInsets.all(AppSpace.l),
                children: [
                  Text(
                    _route(t),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${t.input.direction.name.toUpperCase()} · ${t.input.status.code}',
                  ),
                  Text(
                    'Departure (UTC): ${t.input.scheduledDepartureUtc.toIso8601String()}',
                  ),
                  Text(
                    'Arrival (UTC): ${t.input.scheduledArrivalUtc.toIso8601String()}',
                  ),
                  if (t.input.actualDepartureUtc != null)
                    Text(
                      'Actual departure: ${t.input.actualDepartureUtc!.toIso8601String()}',
                    ),
                  if (t.input.actualArrivalUtc != null)
                    Text(
                      'Actual arrival: ${t.input.actualArrivalUtc!.toIso8601String()}',
                    ),
                  Text('Driver: ${_label(s, 'drivers', t.input.driverId)}'),
                  Text('Vehicle: ${_label(s, 'vehicles', t.input.vehicleId)}'),
                  Text(
                    'Linked flight: ${_label(s, 'flights', t.input.relatedFlightId)}',
                  ),
                  Text('Manager lock: ${t.input.isLocked ? 'On' : 'Off'}'),
                  if (t.input.notes != null) Text(_isolate(t.input.notes!)),
                  Text(
                    'Active passengers: ${t.activePassengers}${t.vehicleCapacity == null ? '' : ' / ${t.vehicleCapacity}'}',
                  ),
                  if (t.overCapacity)
                    _warning(
                      context,
                      'Over capacity. Review the vehicle or passenger assignments; no passengers have been removed.',
                    ),
                  if (t.flightNeedsReview)
                    _warning(
                      context,
                      'Linked flight changed. Review the flight and this trip. The trip schedule is unchanged.',
                    ),
                  TransportFeedback(failure: s.failure, online: s.online),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      FilledButton(
                        onPressed: s.canWrite && !t.isDeleted
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TripEditorPage(
                                    controller: controller,
                                    trip: t,
                                  ),
                                ),
                              )
                            : null,
                        child: const Text('Edit trip'),
                      ),
                      OutlinedButton(
                        onPressed: s.canWrite
                            ? () async {
                                if (await _confirm(
                                  context,
                                  t.isDeleted
                                      ? 'Restore trip?'
                                      : 'Delete trip?',
                                )) {
                                  await controller.setTripDeleted(
                                    t,
                                    !t.isDeleted,
                                  );
                                }
                              }
                            : null,
                        child: Text(t.isDeleted ? 'Restore' : 'Delete'),
                      ),
                      OutlinedButton(
                        onPressed: s.canWrite && !t.isDeleted
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TripPassengerEditor(
                                    controller: controller,
                                    tripId: t.id,
                                  ),
                                ),
                              )
                            : null,
                        child: const Text('Assign passenger'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Deleted passengers'),
                    value: s.deletedPassengers,
                    onChanged: (_) => controller.toggleDeletedPassengers(),
                  ),
                  for (final p in s.passengers)
                    Card(
                      child: ListTile(
                        title: Text(_label(s, 'people', p.input.personId)),
                        subtitle: Text(
                          '${p.input.status.code}\n${_isolate(p.input.pickupLocation ?? 'Pickup not specified')}',
                        ),
                        onTap: s.canWrite && !p.isDeleted && !t.isDeleted
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TripPassengerEditor(
                                    controller: controller,
                                    tripId: t.id,
                                    passenger: p,
                                  ),
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          tooltip: p.isDeleted
                              ? 'Restore passenger'
                              : 'Delete passenger',
                          icon: Icon(
                            p.isDeleted ? Icons.restore : Icons.delete_outline,
                          ),
                          onPressed: s.canWrite && !t.isDeleted
                              ? () async {
                                  if (await _confirm(
                                    context,
                                    p.isDeleted
                                        ? 'Restore passenger?'
                                        : 'Delete passenger?',
                                  )) {
                                    await controller.setPassengerDeleted(
                                      p,
                                      !p.isDeleted,
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

String _label(TripsState s, String key, String? id) => id == null
    ? 'Not assigned'
    : _isolate(
        s.options[key]?.where((o) => o.id == id).firstOrNull?.label ??
            'Unavailable ($id)',
      );
Widget _warning(BuildContext c, String text) => Card(
  color: Theme.of(c).colorScheme.errorContainer,
  child: Padding(
    padding: const EdgeInsets.all(AppSpace.l),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(c).colorScheme.onErrorContainer),
    ),
  ),
);
Future<bool> _confirm(BuildContext c, String title) async =>
    await showDialog<bool>(
      context: c,
      builder: (c) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

class TripEditorPage extends StatefulWidget {
  const TripEditorPage({super.key, required this.controller, this.trip});
  final TripsController controller;
  final Trip? trip;
  @override
  State<TripEditorPage> createState() => _TripEditorState();
}

class _TripEditorState extends State<TripEditorPage> {
  final _form = GlobalKey<FormState>();
  final _request = UuidV4.generate();
  late final Map<String, TextEditingController> _text;
  late TripDirection _direction;
  late TripStatus _status;
  late bool _locked;
  String? _driver, _vehicle, _flight, _error;
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
    final t = widget.trip?.input;
    _direction = t?.direction ?? TripDirection.local;
    _status = t?.status ?? TripStatus.planned;
    _locked = t?.isLocked ?? false;
    _driver = t?.driverId;
    _vehicle = t?.vehicleId;
    _flight = t?.relatedFlightId;
    _text = {
      for (final e in {
        'Origin': t?.origin,
        'Destination': t?.destination,
        'Scheduled departure (UTC)': t?.scheduledDepartureUtc.toIso8601String(),
        'Scheduled arrival (UTC)': t?.scheduledArrivalUtc.toIso8601String(),
        'Actual departure (UTC)': t?.actualDepartureUtc?.toIso8601String(),
        'Actual arrival (UTC)': t?.actualArrivalUtc?.toIso8601String(),
        'Notes': t?.notes,
      }.entries)
        e.key: TextEditingController(text: e.value),
    };
  }

  @override
  void dispose() {
    for (final t in _text.values) {
      t.dispose();
    }
    super.dispose();
  }

  DateTime? _date(String key) {
    final s = _text[key]!.text.trim();
    if (s.isEmpty) return null;
    if (!s.endsWith('Z') && !RegExp(r'[+-]\d\d:\d\d$').hasMatch(s)) {
      throw const FormatException(
        'Enter UTC timestamps with Z, for example 2026-09-26T10:00:00Z.',
      );
    }
    return DateTime.parse(s).toUtc();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      final input = TripInput(
        direction: _direction,
        origin: _text['Origin']!.text,
        destination: _text['Destination']!.text,
        scheduledDepartureUtc: _date('Scheduled departure (UTC)')!,
        scheduledArrivalUtc: _date('Scheduled arrival (UTC)')!,
        actualDepartureUtc: _date('Actual departure (UTC)'),
        actualArrivalUtc: _date('Actual arrival (UTC)'),
        driverId: _driver,
        vehicleId: _vehicle,
        relatedFlightId: _flight,
        status: _status,
        notes: _text['Notes']!.text,
        isLocked: _locked,
      );
      input.validate();
      setState(() => _error = null);
      if (await widget.controller.saveTrip(
            input,
            requestId: _request,
            base: widget.trip,
          ) &&
          mounted) {
        Navigator.pop(context);
      }
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TripsController, TripsState>(
    bloc: widget.controller,
    builder: (context, s) => Scaffold(
      appBar: AppBar(
        title: Text(widget.trip == null ? 'New trip' : 'Edit trip'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.l),
          children: [
            for (final e in _text.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.l),
                child: TextFormField(
                  controller: e.value,
                  decoration: InputDecoration(
                    labelText: e.key,
                    helperText: e.key.contains('UTC')
                        ? 'ISO 8601, e.g. 2026-09-26T10:00:00Z'
                        : null,
                  ),
                  validator: (v) =>
                      (e.key == 'Origin' ||
                              e.key == 'Destination' ||
                              e.key.startsWith('Scheduled')) &&
                          (v?.trim().isEmpty ?? true)
                      ? 'Required'
                      : null,
                ),
              ),
            DropdownButtonFormField<TripDirection>(
              initialValue: _direction,
              decoration: const InputDecoration(labelText: 'Direction'),
              items: TripDirection.values
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _direction = v!),
            ),
            const SizedBox(height: AppSpace.l),
            DropdownButtonFormField<TripStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status (explicit manager choice)',
              ),
              items: TripStatus.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.code)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: AppSpace.l),
            _picker(
              'Driver',
              s.options['drivers'] ?? [],
              _driver,
              (v) => setState(() => _driver = v),
            ),
            _picker(
              'Vehicle',
              s.options['vehicles'] ?? [],
              _vehicle,
              (v) => setState(() => _vehicle = v),
            ),
            _picker(
              'Related flight (advisory)',
              s.options['flights'] ?? [],
              _flight,
              (v) => setState(() => _flight = v),
            ),
            SwitchListTile(
              title: const Text('Manager lock'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
            ),
            const Text(
              'Actual arrival does not change status. Flight changes never change this schedule.',
            ),
            if (_error != null) Text(_error!),
            TransportFeedback(failure: s.failure, online: s.online),
            FilledButton(
              onPressed: s.canWrite && s.save != SaveStatus.conflict
                  ? _save
                  : null,
              child: const Text('Save trip'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _picker(
  String label,
  List<TripAssignmentOption> options,
  String? value,
  ValueChanged<String?> changed, {
  bool required = false,
}) {
  final list = [...options];
  if (value != null && !list.any((o) => o.id == value)) {
    list.add(TripAssignmentOption(value, 'Unavailable ($value)'));
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.l),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!required)
          const DropdownMenuItem(value: null, child: Text('Not assigned')),
        for (final o in list)
          DropdownMenuItem(
            value: o.id,
            child: Text(_isolate(o.label), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: changed,
      validator: (v) => required && v == null ? 'Required' : null,
    ),
  );
}

class TripPassengerEditor extends StatefulWidget {
  const TripPassengerEditor({
    super.key,
    required this.controller,
    required this.tripId,
    this.passenger,
  });
  final TripsController controller;
  final String tripId;
  final TripPassenger? passenger;
  @override
  State<TripPassengerEditor> createState() => _PassengerEditorState();
}

class _PassengerEditorState extends State<TripPassengerEditor> {
  final _form = GlobalKey<FormState>();
  final _request = UuidV4.generate();
  late final TextEditingController _location, _pickupNotes, _notes;
  String? _person;
  late TripPassengerStatus _status;
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
    final p = widget.passenger?.input;
    _person = p?.personId;
    _status = p?.status ?? TripPassengerStatus.assigned;
    _location = TextEditingController(text: p?.pickupLocation);
    _pickupNotes = TextEditingController(text: p?.pickupNotes);
    _notes = TextEditingController(text: p?.notes);
  }

  @override
  void dispose() {
    _location.dispose();
    _pickupNotes.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController c) => c.text.isEmpty ? null : c.text;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TripsController, TripsState>(
    bloc: widget.controller,
    builder: (context, s) => Scaffold(
      appBar: AppBar(title: const Text('Trip passenger')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.l),
          children: [
            _picker(
              'Person',
              s.options['people'] ?? [],
              _person,
              (v) => setState(() => _person = v),
              required: true,
            ),
            for (final e in {
              'Pickup location (optional)': _location,
              'Pickup notes': _pickupNotes,
              'Notes': _notes,
            }.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.l),
                child: TextFormField(
                  controller: e.value,
                  decoration: InputDecoration(labelText: e.key),
                ),
              ),
            DropdownButtonFormField<TripPassengerStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Passenger status'),
              items: TripPassengerStatus.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.code)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            TransportFeedback(failure: s.failure, online: s.online),
            const SizedBox(height: AppSpace.l),
            FilledButton(
              onPressed: s.canWrite && s.save != SaveStatus.conflict
                  ? () async {
                      if (!_form.currentState!.validate()) return;
                      final ok = await widget.controller.savePassenger(
                        TripPassengerInput(
                          tripId: widget.tripId,
                          personId: _person!,
                          pickupLocation: _optional(_location),
                          pickupNotes: _optional(_pickupNotes),
                          notes: _optional(_notes),
                          status: _status,
                        ),
                        requestId: _request,
                        base: widget.passenger,
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    }
                  : null,
              child: const Text('Save passenger'),
            ),
          ],
        ),
      ),
    ),
  );
}
