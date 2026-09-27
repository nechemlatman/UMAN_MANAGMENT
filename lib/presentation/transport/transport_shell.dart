import '../../application/trips_controller.dart';
import 'trips_page.dart';
import 'package:flutter/material.dart';
import '../../application/drivers_controller.dart';
import '../../application/vehicles_controller.dart';
import 'drivers_page.dart';
import 'vehicles_page.dart';

class TransportShell extends StatelessWidget {
  const TransportShell({
    super.key,
    required this.drivers,
    required this.vehicles,
    this.trips,
  });

  final TripsController? trips;
  final DriversController drivers;
  final VehiclesController vehicles;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: trips == null ? 2 : 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              if (trips != null)
                const Tab(icon: Icon(Icons.route), text: 'Trips'),
              Tab(icon: Icon(Icons.person_pin), text: 'Drivers'),
              Tab(icon: Icon(Icons.directions_bus), text: 'Vehicles'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                if (trips != null) TripsPage(controller: trips!),
                DriversPage(controller: drivers),
                VehiclesPage(controller: vehicles),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
