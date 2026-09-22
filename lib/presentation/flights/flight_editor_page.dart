import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../application/flights_controller.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/flights_repository.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

class FlightEditorPage extends StatefulWidget {
  const FlightEditorPage({
    super.key,
    required this.controller,
    this.flight,
  });

  final FlightsController controller;
  final Flight? flight;

  @override
  State<FlightEditorPage> createState() => _FlightEditorPageState();
}

class _FlightEditorPageState extends State<FlightEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();

  late FlightDirection _direction = widget.flight?.direction ?? FlightDirection.inbound;
  late final _airline = TextEditingController(text: widget.flight?.airline);
  late final _flightNumber = TextEditingController(text: widget.flight?.flightNumber);
  late final _departureAirport = TextEditingController(text: widget.flight?.departureAirport);
  late final _arrivalAirport = TextEditingController(text: widget.flight?.arrivalAirport);
  late DateTime _scheduledDeparture = widget.flight?.scheduledDepartureUtc.toLocal() ?? DateTime.now();
  late DateTime _scheduledArrival = widget.flight?.scheduledArrivalUtc.toLocal() ?? DateTime.now().add(const Duration(hours: 3));
  late FlightStatus _status = widget.flight?.status ?? FlightStatus.scheduled;
  late final _terminal = TextEditingController(text: widget.flight?.terminal);
  late final _gate = TextEditingController(text: widget.flight?.gate);
  late final _notes = TextEditingController(text: widget.flight?.notes);
  late bool _isLocked = widget.flight?.isLocked ?? false;

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
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => _direction = v!),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _airline,
                  decoration: const InputDecoration(labelText: 'Airline'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _flightNumber,
                  decoration: const InputDecoration(labelText: 'Flight Number'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _departureAirport,
                  decoration: const InputDecoration(labelText: 'Departure Airport'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _arrivalAirport,
                  decoration: const InputDecoration(labelText: 'Arrival Airport'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                ListTile(
                  title: const Text('Scheduled Departure'),
                  subtitle: Text(_scheduledDeparture.toString()),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _scheduledDeparture,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && mounted) {
                      if (!context.mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledDeparture),
                      );
                      if (t != null && mounted) {
                        setState(() => _scheduledDeparture = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('Scheduled Arrival'),
                  subtitle: Text(_scheduledArrival.toString()),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _scheduledArrival,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && mounted) {
                      if (!context.mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_scheduledArrival),
                      );
                      if (t != null && mounted) {
                        setState(() => _scheduledArrival = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<FlightStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: FlightStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
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
                if (state.save == SaveStatus.saving)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final navigator = Navigator.of(context);
                      final ok = await widget.controller.saveFlight(
                        FlightInput(
                          direction: _direction,
                          airline: _airline.text,
                          flightNumber: _flightNumber.text,
                          departureAirport: _departureAirport.text,
                          arrivalAirport: _arrivalAirport.text,
                          scheduledDepartureUtc: _scheduledDeparture.toUtc(),
                          scheduledArrivalUtc: _scheduledArrival.toUtc(),
                          status: _status,
                          terminal: _terminal.text,
                          gate: _gate.text,
                          notes: _notes.text,
                          isLocked: _isLocked,
                        ),
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
