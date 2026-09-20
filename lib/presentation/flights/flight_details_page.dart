import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/flights_controller.dart';
import '../../domain/repositories/people_repository.dart';
import '../design_system.dart';
import 'flight_editor_page.dart';
import 'passenger_editor.dart';

class FlightDetailsPage extends StatefulWidget {
  const FlightDetailsPage({
    super.key,
    required this.controller,
    required this.peopleRepository,
    required this.flightId,
  });

  final FlightsController controller;
  final PeopleRepository peopleRepository;
  final String flightId;

  @override
  State<FlightDetailsPage> createState() => _FlightDetailsPageState();
}

class _FlightDetailsPageState extends State<FlightDetailsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.selectFlight(widget.flightId));
  }

  @override
  void dispose() {
    unawaited(widget.controller.selectFlight(null));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightsController, FlightsState>(
      bloc: widget.controller,
      builder: (context, state) {
        final flight = state.selectedFlight;
        if (flight == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flight Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(BidiTextFormatter.isolate('${flight.airline} ${flight.flightNumber}')),
            actions: [
              if (state.canWrite) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => FlightEditorPage(
                        controller: widget.controller,
                        flight: flight,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(flight.isDeleted ? Icons.restore : Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(flight.isDeleted ? 'Restore Flight?' : 'Delete Flight?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(flight.isDeleted ? 'Restore' : 'Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.controller.setFlightDeleted(flight, !flight.isDeleted);
                      if (context.mounted && !flight.isDeleted) Navigator.pop(context);
                    }
                  },
                ),
              ]
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              _infoRow('Status', flight.status.displayName),
              _infoRow('Direction', flight.direction.name.toUpperCase()),
              _infoRow('From', flight.departureAirport),
              _infoRow('To', flight.arrivalAirport),
              _infoRow('Scheduled Departure', flight.scheduledDepartureUtc.toLocal().toString()),
              _infoRow('Scheduled Arrival', flight.scheduledArrivalUtc.toLocal().toString()),
              if (flight.actualDepartureUtc != null)
                _infoRow('Actual Departure', flight.actualDepartureUtc!.toLocal().toString()),
              if (flight.actualArrivalUtc != null)
                _infoRow('Actual Arrival', flight.actualArrivalUtc!.toLocal().toString()),
              if (flight.delayMinutes != null)
                _infoRow('Delay', '${flight.delayMinutes} min'),
              if (flight.terminal != null) _infoRow('Terminal', flight.terminal!),
              if (flight.gate != null) _infoRow('Gate', flight.gate!),
              if (flight.notes != null) _infoRow('Notes', flight.notes!),
              const Divider(height: AppSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Passengers', style: Theme.of(context).textTheme.titleLarge),
                  if (state.canWrite)
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PassengerEditor(
                            controller: widget.controller,
                            peopleRepository: widget.peopleRepository,
                            flight: flight,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                ],
              ),
              if (state.passengers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.l),
                  child: Center(child: Text('No passengers assigned.')),
                )
              else
                ...state.passengers.map((p) => ListTile(
                      title: Text(BidiTextFormatter.isolate(p.personFullName)),
                      subtitle: Text('Seat: ${p.seatNumber ?? '-'} · ${p.status.displayName}'),
                      trailing: state.canWrite
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => widget.controller.removePassenger(p),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PassengerEditor(
                            controller: widget.controller,
                            peopleRepository: widget.peopleRepository,
                            flight: flight,
                            base: p,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(BidiTextFormatter.isolate(value))),
        ],
      ),
    );
  }
}
