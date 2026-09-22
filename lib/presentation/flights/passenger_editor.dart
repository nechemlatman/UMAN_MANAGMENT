import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../application/flights_controller.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/flights_repository.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

class PassengerEditor extends StatefulWidget {
  const PassengerEditor({
    super.key,
    required this.controller,
    required this.peopleRepository,
    required this.flight,
    this.base,
  });

  final FlightsController controller;
  final PeopleRepository peopleRepository;
  final Flight flight;
  final FlightPassenger? base;

  @override
  State<PassengerEditor> createState() => _PassengerEditorState();
}

class _PassengerEditorState extends State<PassengerEditor> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = UuidV4.generate();

  String? _personId;
  String? _personName;
  late final _seatNumber = TextEditingController(text: widget.base?.seatNumber);
  late final _bookingReference = TextEditingController(text: widget.base?.bookingReference);
  late final _notes = TextEditingController(text: widget.base?.notes);
  late FlightPassengerStatus _status = widget.base?.status ?? FlightPassengerStatus.confirmed;

  @override
  void initState() {
    super.initState();
    if (widget.base != null) {
      _personId = widget.base!.personId;
      _personName = widget.base!.personFullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightsController, FlightsState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.base == null ? 'Add Passenger' : 'Edit Passenger'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.l),
              children: [
                TextFormField(
                  controller: TextEditingController(text: _personName),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Person',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onTap: widget.base != null ? null : () async {
                    final p = await showSearch<PersonSummary?>(
                      context: context,
                      delegate: PersonSearchDelegate(
                        peopleRepository: widget.peopleRepository,
                      ),
                    );
                    if (p != null && mounted) {
                      setState(() {
                        _personId = p.id;
                        _personName = p.displayName;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _seatNumber,
                  decoration: const InputDecoration(labelText: 'Seat Number'),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _bookingReference,
                  decoration: const InputDecoration(labelText: 'Booking Reference'),
                ),
                const SizedBox(height: AppSpace.m),
                DropdownButtonFormField<FlightPassengerStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: FlightPassengerStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: AppSpace.m),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpace.xl),
                if (state.save == SaveStatus.saving)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: _personId == null
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final navigator = Navigator.of(context);
                            final ok = await widget.controller.savePassenger(
                              FlightPassengerInput(
                                flightId: widget.flight.id,
                                personId: _personId!,
                                seatNumber: _seatNumber.text,
                                bookingReference: _bookingReference.text,
                                notes: _notes.text,
                                status: _status,
                              ),
                              requestId: _requestId,
                              base: widget.base,
                            );
                            if (ok && mounted) navigator.pop();
                          },
                    child: const Text('Save Passenger'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PersonSearchDelegate extends SearchDelegate<PersonSummary?> {
  PersonSearchDelegate({required this.peopleRepository});
  final PeopleRepository peopleRepository;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    return FutureBuilder<List<PersonSummary>>(
      future: peopleRepository.readPage(query: query, deleted: false, limit: 50, offset: 0),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final people = snapshot.data!;
        return ListView.builder(
          itemCount: people.length,
          itemBuilder: (context, i) {
            final p = people[i];
            return ListTile(
              title: Text(BidiTextFormatter.isolate(p.displayName)),
              onTap: () => close(context, p),
            );
          },
        );
      },
    );
  }
}
