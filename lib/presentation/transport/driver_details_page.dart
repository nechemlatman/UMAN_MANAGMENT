import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/drivers_controller.dart';
import '../../domain/entities/driver.dart';
import '../design_system.dart';
import 'transport_feedback.dart';
import 'driver_editor_page.dart';

class DriverDetailsPage extends StatelessWidget {
  const DriverDetailsPage({
    super.key,
    required this.controller,
    required this.driver,
  });

  final DriversController controller;
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriversController, DriversState>(
      bloc: controller,
      builder: (context, state) {
        final current = state.selectedDriver;
        if (!state.accessible || current == null || current.id != driver.id) {
          return Scaffold(appBar: AppBar(title: const Text('Driver unavailable')),
            body: TransportFeedback(failure: state.failure, online: state.online));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(BidiTextFormatter.isolate(current.fullName)),
            actions: [
              if (state.canWrite && current.isDeleted)
                IconButton(tooltip: 'Restore Driver', icon: const Icon(Icons.restore),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await controller.restoreDriver(current) && context.mounted) nav.pop();
                  }),
              if (state.canWrite && !current.isDeleted)
                IconButton(
                  tooltip: 'Edit Driver',
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverEditorPage(
                          controller: controller,
                          driver: current,
                        ),
                      ),
                    );
                  },
                ),
              if (state.canWrite && !current.isDeleted)
                IconButton(
                  tooltip: 'Delete Driver',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Driver'),
                        content: Text('Delete ${current.fullName}?'),
                        actions: [
              if (state.canWrite && current.isDeleted)
                IconButton(tooltip: 'Restore Driver', icon: const Icon(Icons.restore),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await controller.restoreDriver(current) && context.mounted) nav.pop();
                  }),
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
                      final ok = await controller.deleteDriver(current);
                      if (ok) nav.pop();
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              TransportFeedback(failure: state.failure, online: state.online),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              BidiTextFormatter.isolate(current.fullName),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Chip(label: Text(current.status.displayName)),
                        ],
                      ),
                      const Divider(height: AppSpace.l),
                      _infoRow('Phone', current.phoneNumber),
                      _infoRow('License Info', current.licenseNumber),
                      _infoRow('WhatsApp Phone', current.whatsappPhone),
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
          Expanded(child: Text(BidiTextFormatter.isolate(value))),
        ],
      ),
    );
  }
}
