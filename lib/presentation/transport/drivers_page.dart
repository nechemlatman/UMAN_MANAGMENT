import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/drivers_controller.dart';
import '../../domain/entities/driver.dart';
import '../design_system.dart';
import 'driver_details_page.dart';
import 'driver_editor_page.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key, required this.controller});
  final DriversController controller;

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
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
    return BlocBuilder<DriversController, DriversState>(
      bloc: widget.controller,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Drivers'),
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
              Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search drivers...',
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
                        builder: (_) => DriverEditorPage(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Driver'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DriversState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state.load == DriversLoad.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.load == DriversLoad.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: AppSpace.m),
            const Text('Failed to load drivers'),
            const SizedBox(height: AppSpace.s),
            FilledButton(
              onPressed: () => widget.controller.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.drivers.isEmpty) {
      return const Center(
        child: Text('No drivers found'),
      );
    }

    return ListView.builder(
      itemCount: state.drivers.length,
      itemBuilder: (context, index) {
        final driver = state.drivers[index];
        final isActive = driver.status == DriverStatus.active;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              color: isActive
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            BidiTextFormatter.isolate(driver.fullName),
            style: TextStyle(
              decoration: driver.isDeleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            [
              if (driver.phoneNumber.isNotEmpty)
                BidiTextFormatter.isolate(driver.phoneNumber),
              if (driver.licenseNumber.isNotEmpty)
                'Lic: ${BidiTextFormatter.isolate(driver.licenseNumber)}',
            ].join(' • '),
          ),
          trailing: Chip(
            label: Text(
              driver.status.displayName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onTap: () {
            widget.controller.selectDriver(driver);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverDetailsPage(
                  controller: widget.controller,
                  driver: driver,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
