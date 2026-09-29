import '../forms/optional_timestamp.dart';
import '../transport/transport_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../application/flights_controller.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/flights_repository.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

class FlightEditorPage extends StatefulWidget {
  const FlightEditorPage({super.key, required this.controller, this.flight});

  final FlightsController controller;
  final Flight? flight;

  @override
  State<FlightEditorPage> createState() => _FlightEditorPageState();
}

class _FlightEditorPageState extends State<FlightEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();

  late FlightDirection _direction =
      widget.flight?.direction ?? FlightDirection.inbound;
  late final _airline = TextEditingController(text: widget.flight?.airline);
  late final _flightNumber = TextEditingController(
    text: widget.flight?.flightNumber,
  );
  late final _departureAirport = TextEditingController(
    text: widget.flight?.departureAirport,
  );
  late final _arrivalAirport = TextEditingController(
    text: widget.flight?.arrivalAirport,
  );
  late DateTime? _scheduledDeparture = widget.flight?.scheduledDepartureUtc;
  late DateTime? _scheduledArrival = widget.flight?.scheduledArrivalUtc;
  late DateTime? _actualDeparture = widget.flight?.actualDepartureUtc,
      _actualArrival = widget.flight?.actualArrivalUtc;
  String? _error;
  late FlightStatus _status = widget.flight?.status ?? FlightStatus.draft;
  late final _terminal = TextEditingController(text: widget.flight?.terminal);
  late final _gate = TextEditingController(text: widget.flight?.gate);
  late final _notes = TextEditingController(text: widget.flight?.notes);
  late bool _isLocked = widget.flight?.isLocked ?? false;

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
  }

  @override
  void dispose() {
    for (final c in [
      _airline,
      _flightNumber,
      _departureAirport,
      _arrivalAirport,
      _terminal,
      _gate,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightsController, FlightsState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.flight == null ? 'Add Flight' : 'Edit Flight'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.l),
              children: [
                DropdownButtonFormField<FlightDirection>(
                  initialValue: _direction,
                  decoration: const InputDecoration(labelText: 'Direction'),
                  items: FlightDirection.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _direction = v!),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _airline,
                  decoration: const InputDecoration(labelText: 'Airline'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _flightNumber,
                  decoration: const InputDecoration(labelText: 'Flight Number'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _departureAirport,
                  decoration: const InputDecoration(
                    labelText: 'Departure Airport',
                  ),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _arrivalAirport,
                  decoration: const InputDecoration(
                    labelText: 'Arrival Airport',
                  ),
                ),
                const SizedBox(height: AppSpace.m),
                OptionalTimestampField(
                  label: 'Scheduled Departure',
                  value: _scheduledDeparture,
                  enabled: state.canWrite,
                  onChanged: (v) => setState(() => _scheduledDeparture = v),
                ),
                OptionalTimestampField(
                  label: 'Scheduled Arrival',
                  value: _scheduledArrival,
                  enabled: state.canWrite,
                  onChanged: (v) => setState(() => _scheduledArrival = v),
                ),
                OptionalTimestampField(
                  label: 'Actual Departure',
                  value: _actualDeparture,
                  enabled: state.canWrite,
                  onChanged: (v) => setState(() => _actualDeparture = v),
                ),
                OptionalTimestampField(
                  label: 'Actual Arrival',
                  value: _actualArrival,
                  enabled: state.canWrite,
                  onChanged: (v) => setState(() => _actualArrival = v),
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<FlightStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: FlightStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _terminal,
                  decoration: const InputDecoration(labelText: 'Terminal'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _gate,
                  decoration: const InputDecoration(labelText: 'Gate'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                CheckboxListTile(
                  title: const Text('Locked'),
                  value: _isLocked,
                  onChanged: (v) => setState(() => _isLocked = v!),
                ),
                const SizedBox(height: AppSpace.xl),
                if (_error != null) Text(_error!),
                TransportFeedback(failure: state.failure, online: state.online),
                if (state.save == SaveStatus.saving)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed:
                        !state.canWrite || state.save == SaveStatus.conflict
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final navigator = Navigator.of(context);
                            final input = FlightInput(
                              direction: _direction,
                              airline: _optional(_airline),
                              flightNumber: _optional(_flightNumber),
                              departureAirport: _optional(_departureAirport),
                              arrivalAirport: _optional(_arrivalAirport),
                              scheduledDepartureUtc: _scheduledDeparture,
                              scheduledArrivalUtc: _scheduledArrival,
                              actualDepartureUtc: _actualDeparture,
                              actualArrivalUtc: _actualArrival,
                              delayMinutes: widget.flight?.delayMinutes,
                              status: _status,
                              terminal: _terminal.text,
                              gate: _gate.text,
                              notes: _notes.text,
                              isLocked: _isLocked,
                            );
                            try {
                              input.validate();
                            } on FormatException catch (e) {
                              setState(() => _error = e.message);
                              return;
                            }
                            setState(() => _error = null);
                            final ok = await widget.controller.saveFlight(
                              input,
                              requestId: _requestId,
                              base: widget.flight,
                            );
                            if (ok && mounted) navigator.pop();
                          },
                    child: const Text('Save Flight'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
