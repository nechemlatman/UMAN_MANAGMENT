import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/vehicles_controller.dart';
import '../../domain/entities/vehicle.dart';
import '../design_system.dart';
import 'vehicle_editor_page.dart';

class VehicleDetailsPage extends StatelessWidget {
  const VehicleDetailsPage({
    super.key,
    required this.controller,
    required this.vehicle,
  });

  final VehiclesController controller;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehiclesController, VehiclesState>(
      bloc: controller,
      builder: (context, state) {
        final current = state.vehicles.firstWhere(
          (v) => v.id == vehicle.id,
          orElse: () => vehicle,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(current.name),
            actions: [
              if (state.canWrite && !current.isDeleted)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleEditorPage(
                          controller: controller,
                          vehicle: current,
                        ),
                      ),
                    );
                  },
                ),
              if (state.canWrite && !current.isDeleted)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Vehicle'),
                        content: Text('Delete ${current.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final nav = Navigator.of(context);
                      final ok = await controller.deleteVehicle(current);
                      if (ok) nav.pop();
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            current.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Chip(label: Text(current.status.displayName)),
                        ],
                      ),
                      const Divider(height: AppSpace.l),
                      _infoRow('Type', current.type.displayName),
                      _infoRow('Capacity', '${current.capacity} passengers'),
                      _infoRow('License Plate', current.licensePlate),
                      _infoRow('Notes', current.notes),
                      _infoRow('Version', current.version.toString()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
