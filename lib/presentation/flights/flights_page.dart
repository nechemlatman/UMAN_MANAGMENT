import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/flights_controller.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/people_repository.dart';
import '../design_system.dart';
import 'flight_details_page.dart';
import 'flight_editor_page.dart';

class FlightsPage extends StatelessWidget {
  const FlightsPage({
    super.key,
    required this.controller,
    required this.peopleRepository,
  });

  final FlightsController controller;
  final PeopleRepository peopleRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightsController, FlightsState>(
      bloc: controller,
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: state.query,
                    key: const ValueKey('flights-search'),
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Search airline, number or airport',
                    ),
                    onChanged: controller.search,
                  ),
                  CheckboxListTile(
                    title: const Text('Show deleted flights'),
                    value: state.deleted,
                    onChanged: (v) => controller.toggleDeleted(),
                  ),
                  if (!state.accessible)
                    const Text('Not authorized or event unavailable')
                  else if (!state.online && state.synchronizedAt != null)
                    Text(
                      'Offline — last synchronized ${state.synchronizedAt!.toLocal()}. Read-only.',
                    )
                  else if (!state.realtimeConnected && state.online)
                    const Text(
                      'Live updates reconnecting. Checking for changes periodically.',
                    ),
                  if (state.online && !state.writable)
                    const Text('Event is read-only.'),
                  if (state.load == FlightsLoad.error)
                    const Text('Error loading flights.'),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      FilledButton.icon(
                        onPressed: state.canWrite
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => FlightEditorPage(
                                      controller: controller,
                                    ),
                                  ),
                                )
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Flight'),
                      ),
                      TextButton(
                        onPressed: controller.reconcile,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (state.load == FlightsLoad.loading) const LinearProgressIndicator(),
            Expanded(
              child: state.load == FlightsLoad.empty
                  ? Center(
                      child: Text(
                        state.deleted ? 'No deleted flights.' : 'No flights yet.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.flights.length,
                      itemBuilder: (context, i) {
                        final f = state.flights[i];
                        return ListTile(
                          key: ValueKey(f.id),
                          leading: Icon(
                            f.direction == FlightDirection.inbound
                                ? Icons.flight_land
                                : Icons.flight_takeoff,
                            color: AppTheme.primary,
                          ),
                          title: Text(
                            BidiTextFormatter.isolate(
                                '${f.airline} ${f.flightNumber}'),
                          ),
                          subtitle: Text(
                            '${f.departureAirport} → ${f.arrivalAirport} · ${f.scheduledArrivalUtc.toLocal()}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(f.status.displayName),
                            ],
                          ),
                          onTap: state.online
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => FlightDetailsPage(
                                        controller: controller,
                                        peopleRepository: peopleRepository,
                                        flightId: f.id,
                                      ),
                                    ),
                                  )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
