import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/vehicles_controller.dart';
import '../../domain/entities/vehicle.dart';
import '../design_system.dart';
import 'transport_feedback.dart';
import 'vehicle_details_page.dart';
import 'vehicle_editor_page.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key, required this.controller});
  final VehiclesController controller;

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  VehicleStatus? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehiclesController, VehiclesState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Vehicles'),
            actions: [
              IconButton(
                icon: Icon(
                  state.deleted ? Icons.visibility : Icons.visibility_off_outlined,
                ),
                tooltip: state.deleted ? 'Hide Deleted' : 'Show Deleted',
                onPressed: () => widget.controller.toggleIncludeDeleted(),
              ),
            ],
          ),
          body: Column(
            children: [
              TransportFeedback(failure: state.failure, online: state.online),
              Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.controller.updateQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => widget.controller.updateQuery(v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                child: DropdownButtonFormField<VehicleStatus>(
                  decoration: const InputDecoration(labelText: 'Availability'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    for (final status in VehicleStatus.values)
                      DropdownMenuItem(value: status, child: Text(status.displayName)),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              ),
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          ),
          floatingActionButton: state.canWrite
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleEditorPage(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, VehiclesState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state.load == VehiclesLoad.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.load == VehiclesLoad.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: AppSpace.m),
            const Text('Failed to load vehicles'),
            const SizedBox(height: AppSpace.s),
            FilledButton(
              onPressed: () => widget.controller.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final rows = state.vehicles.where((row) => _statusFilter == null || row.status == _statusFilter).toList();
    if (rows.isEmpty) {
      return const Center(
        child: Text('No vehicles found'),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final vehicle = rows[index];
        final isAvailable = vehicle.status == VehicleStatus.available;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isAvailable
                ? scheme.primaryContainer
                : scheme.tertiaryContainer,
            child: Icon(
              Icons.directions_bus,
              color: isAvailable
                  ? scheme.onPrimaryContainer
                  : scheme.onTertiaryContainer,
            ),
          ),
          title: Text(
            BidiTextFormatter.isolate(vehicle.name),
            style: TextStyle(
              decoration: vehicle.isDeleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            [
              vehicle.type.displayName,
              'Cap: ${vehicle.capacity}',
              if (vehicle.licensePlate.isNotEmpty)
                'Plate: ${BidiTextFormatter.isolate(vehicle.licensePlate)}',
            ].join(' • '),
          ),
          trailing: Chip(
            label: Text(
              vehicle.status.displayName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onTap: () {
            widget.controller.selectVehicle(vehicle);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailsPage(
                  controller: widget.controller,
                  vehicle: vehicle,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
