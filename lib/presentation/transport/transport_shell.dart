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
  });

  final DriversController drivers;
  final VehiclesController vehicles;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_pin), text: 'Drivers'),
              Tab(icon: Icon(Icons.directions_bus), text: 'Vehicles'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
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
