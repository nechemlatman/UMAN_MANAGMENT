import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/drivers_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/driver.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';
import 'transport_feedback.dart';

class DriverEditorPage extends StatefulWidget {
  const DriverEditorPage({super.key, required this.controller, this.driver});

  final DriversController controller;
  final Driver? driver;

  @override
  State<DriverEditorPage> createState() => _DriverEditorPageState();
}

class _DriverEditorPageState extends State<DriverEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();

  late final _fullName = TextEditingController(text: widget.driver?.fullName);
  late final _phoneNumber = TextEditingController(
    text: widget.driver?.phoneNumber,
  );
  late final _licenseNumber = TextEditingController(
    text: widget.driver?.licenseNumber,
  );
  late final _whatsappPhone = TextEditingController(
    text: widget.driver?.whatsappPhone,
  );
  late final _notes = TextEditingController(text: widget.driver?.notes);
  late DriverStatus _status = widget.driver?.status ?? DriverStatus.available;

  @override
  void initState() {
    super.initState();
    widget.controller.beginEdit();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phoneNumber.dispose();
    _licenseNumber.dispose();
    _whatsappPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriversController, DriversState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.driver == null ? 'Add Driver' : 'Edit Driver'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.l),
              children: [
                TransportFeedback(failure: state.failure, online: state.online),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _phoneNumber,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _licenseNumber,
                  decoration: const InputDecoration(labelText: 'License Info'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _whatsappPhone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone',
                  ),
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<DriverStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: DriverStatus.values
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
                            final ok = await widget.controller.saveDriver(
                              DriverInput(
                                fullName: _fullName.text.trim(),
                                phoneNumber: _phoneNumber.text.trim(),
                                licenseNumber: _licenseNumber.text.trim(),
                                whatsappPhone: _whatsappPhone.text.trim(),
                                notes: _notes.text.trim(),
                                status: _status,
                              ),
                              requestId: _requestId,
                              base: widget.driver,
                            );
                            if (ok && mounted) nav.pop();
                          },
                    child: const Text('Save Driver'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
