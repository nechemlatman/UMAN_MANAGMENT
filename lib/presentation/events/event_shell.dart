import '../../application/tasks_controller.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../tasks/tasks_page.dart';
import '../../application/accommodation_controller.dart';
import '../../domain/repositories/accommodation_repository.dart';
import '../accommodation/accommodation_pages.dart';
import '../../application/trips_controller.dart';
import '../../domain/repositories/trips_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/drivers_controller.dart';
import '../../application/event_controller.dart';
import '../../application/flights_controller.dart';
import '../../application/people_controller.dart';
import '../../application/vehicles_controller.dart';
import '../../domain/repositories/flights_repository.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/repositories/transport_repository.dart';
import '../flights/flights_page.dart';
import '../people/people_page.dart';
import '../transport/transport_shell.dart';
import 'event_details.dart';

typedef TasksRepositoryFactory = TasksRepository Function(String eventId);

typedef AccommodationRepositoryFactory =
    AccommodationRepository Function(String eventId);
typedef TripsRepositoryFactory = TripsRepository Function(String eventId);
typedef PeopleRepositoryFactory = PeopleRepository Function(String eventId);
typedef FlightsRepositoryFactory = FlightsRepository Function(String eventId);
typedef TransportRepositoryFactory =
    TransportRepository Function(String eventId);

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
    required this.transportFactory,
    this.tripsFactory,
    this.accommodationFactory,
    this.tasksFactory,
  });
  final EventController events;
  final String eventId;
  final PeopleRepositoryFactory peopleFactory;
  final FlightsRepositoryFactory flightsFactory;
  final TransportRepositoryFactory transportFactory;
  final TripsRepositoryFactory? tripsFactory;
  final AccommodationRepositoryFactory? accommodationFactory;
  final TasksRepositoryFactory? tasksFactory;

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
  late final drivers = DriversController.forEvent(
    widget.transportFactory(widget.eventId),
    widget.eventId,
    widget.events,
  );
  late final vehicles = VehiclesController.forEvent(
    widget.transportFactory(widget.eventId),
    widget.eventId,
    widget.events,
  );

  late final trips = widget.tripsFactory == null
      ? null
      : TripsController(widget.tripsFactory!(widget.eventId), widget.events);
  late final accommodation = widget.accommodationFactory == null
      ? null
      : AccommodationController(
          widget.accommodationFactory!(widget.eventId),
          widget.events,
        );
  late final tasks = widget.tasksFactory == null
      ? null
      : TasksController(widget.tasksFactory!(widget.eventId), widget.events);
  EventModule module = EventModule.people;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(people.start());
    unawaited(flights.start());
    drivers.start();
    trips?.start();
    accommodation?.start();
    tasks?.start();
    vehicles.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.events.reconcile());
      unawaited(people.reconcile());
      unawaited(flights.reconcile());
      unawaited(drivers.refresh());
      unawaited(trips?.refresh());
      unawaited(accommodation?.refresh());
      unawaited(tasks?.refresh());
      unawaited(vehicles.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(people.close());
    unawaited(flights.close());
    unawaited(drivers.close());
    unawaited(trips?.close());
    unawaited(accommodation?.close());
    unawaited(tasks?.close());
    unawaited(vehicles.close());
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
          title: Text(available ? module.label : 'Event unavailable'),
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
                      // Keep future domain intent in the enum, outside operational navigation.
                      for (final item in [
                        EventModule.people,
                        EventModule.flights,
                        EventModule.transport,
                        if (accommodation != null) EventModule.accommodation,
                        if (tasks != null) EventModule.tasks,
                        EventModule.settings,
                      ])
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
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('Return to Events'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
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
              : module == EventModule.accommodation && accommodation != null
              ? ApartmentsPage(controller: accommodation!)
              : module == EventModule.tasks && tasks != null
              ? TasksPage(controller: tasks!)
              : module == EventModule.transport
              ? TransportShell(
                  trips: trips,
                  drivers: drivers,
                  vehicles: vehicles,
                )
              : const Center(
                  child: Text('Module unavailable. Select another module.'),
                ),
        ),
      );
    },
  );
}
