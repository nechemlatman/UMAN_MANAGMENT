import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../application/people_controller.dart';
import '../../application/flights_controller.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/repositories/flights_repository.dart';
import '../people/people_page.dart';
import '../flights/flights_page.dart';
import 'event_details.dart';

typedef PeopleRepositoryFactory = PeopleRepository Function(String eventId);
typedef FlightsRepositoryFactory = FlightsRepository Function(String eventId);

enum EventModule {
  dashboard('Control Center / Dashboard'),
  people('People'),
  flights('Flights'),
  transport('Transport'),
  accommodation('Accommodation'),
  tasks('Tasks'),
  apartmentIssues('Apartment Issues'),
  finance('Finance'),
  unresolved('Unresolved Items'),
  settings('Event Settings');

  const EventModule(this.label);
  final String label;
}

/// The route is the active-event boundary. Leaving disposes its subscriptions.
class EventShell extends StatefulWidget {
  const EventShell({
    super.key,
    required this.events,
    required this.eventId,
    required this.peopleFactory,
    required this.flightsFactory,
  });
  final EventController events;
  final String eventId;
  final PeopleRepositoryFactory peopleFactory;
  final FlightsRepositoryFactory flightsFactory;
  @override
  State<EventShell> createState() => _EventShellState();
}

class _EventShellState extends State<EventShell> with WidgetsBindingObserver {
  late final people = PeopleController(
    widget.peopleFactory(widget.eventId),
    widget.events,
  );
  late final flights = FlightsController(
    widget.flightsFactory(widget.eventId),
    widget.events,
  );
  EventModule module = EventModule.dashboard;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(people.start());
    unawaited(flights.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.events.reconcile());
      unawaited(people.reconcile());
      unawaited(flights.reconcile());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(people.close());
    unawaited(flights.close());
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EventController, EventState>(
    bloc: widget.events,
    builder: (context, state) {
      final event = state.capabilities(widget.eventId).event;
      final available =
          state.authenticated && event != null && !event.isDeleted;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            available ? '${event.name} — ${module.label}' : 'Event unavailable',
          ),
          actions: [
            IconButton(
              tooltip: 'Return to Events',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
        drawer: available
            ? Drawer(
                child: SafeArea(
                  child: ListView(
                    children: [
                      ListTile(title: Text(event.name)),
                      for (final item in EventModule.values)
                        ListTile(
                          title: Text(item.label),
                          selected: module == item,
                          onTap: () {
                            Navigator.pop(context);
                            if (item == EventModule.settings) {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => EventDetailsPage(
                                    controller: widget.events,
                                    eventId: widget.eventId,
                                  ),
                                ),
                              );
                            } else {
                              setState(() => module = item);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: !available
              ? const Center(
                  child: Text(
                    'Select an available event from Events. Access may have changed.',
                  ),
                )
              : module == EventModule.people
              ? PeoplePage(controller: people)
              : module == EventModule.flights
              ? FlightsPage(
                  controller: flights,
                  peopleRepository: people.repository,
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${module.label} — functionality will be added in a later phase.',
                      ),
                      if (module == EventModule.dashboard)
                        FilledButton(
                          onPressed: () =>
                              setState(() => module = EventModule.people),
                          child: const Text('Open People'),
                        ),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}
