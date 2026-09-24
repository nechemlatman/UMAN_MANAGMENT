import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../application/vehicles_controller.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';
import 'transport_feedback.dart';

class VehicleEditorPage extends StatefulWidget {
  const VehicleEditorPage({super.key, required this.controller, this.vehicle});

  final VehiclesController controller;
  final Vehicle? vehicle;

  @override
  State<VehicleEditorPage> createState() => _VehicleEditorPageState();
}

class _VehicleEditorPageState extends State<VehicleEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();

  late final _name = TextEditingController(text: widget.vehicle?.name);
  late final _licensePlate = TextEditingController(
    text: widget.vehicle?.licensePlate,
  );
  late final _capacity = TextEditingController(
    text: widget.vehicle?.capacity.toString() ?? '16',
  );
  late final _color = TextEditingController(text: widget.vehicle?.color);
  late final _notes = TextEditingController(text: widget.vehicle?.notes);
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.van;
  late VehicleStatus _status =
      widget.vehicle?.status ?? VehicleStatus.available;

  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
  }

  @override
  void dispose() {
    _name.dispose();
    _licensePlate.dispose();
    _capacity.dispose();
    _color.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehiclesController, VehiclesState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.l),
              children: [
                TransportFeedback(failure: state.failure, online: state.online),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Name *',
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<VehicleType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                  items: VehicleType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _capacity,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (Passengers) *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final cap = int.tryParse(v?.trim() ?? '');
                    if (cap == null || cap < 1) return 'Must be at least 1';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _licensePlate,
                  decoration: const InputDecoration(labelText: 'License Plate'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _color,
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<VehicleStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: VehicleStatus.values
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
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpace.xl),
                if (state.save == SaveStatus.saving)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed:
                        !state.canWrite || state.save == SaveStatus.conflict
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final nav = Navigator.of(context);
                            final ok = await widget.controller.saveVehicle(
                              VehicleInput(
                                name: _name.text.trim(),
                                type: _type,
                                capacity: int.parse(_capacity.text.trim()),
                                licensePlate: _licensePlate.text.trim(),
                                status: _status,
                                color: _color.text.trim(),
                                notes: _notes.text.trim(),
                              ),
                              requestId: _requestId,
                              base: widget.vehicle,
                            );
                            if (ok && mounted) nav.pop();
                          },
                    child: const Text('Save Vehicle'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
