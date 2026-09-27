import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/people_controller.dart';
import '../../domain/entities/person.dart';
import '../design_system.dart';
import 'person_details.dart';
import 'person_editor.dart';
import 'person_labels.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key, required this.controller});
  final PeopleController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeopleController, PeopleState>(
      bloc: controller,
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Contextual Hero Banner
                AppScreenBanner(
                  title: 'People Directory',
                  subtitle:
                      'Event participants, contacts, and operational roles.',
                  icon: Icons.people_outline,
                  metrics: [
                    AppBannerMetric(
                      label: 'Showing',
                      value: '${state.rows.length}',
                      icon: Icons.group,
                    ),
                    AppBannerMetric(
                      label: 'Status',
                      value: state.online ? 'Online' : 'Offline',
                      icon: state.online ? Icons.wifi : Icons.wifi_off,
                    ),
                    if (state.deleted)
                      const AppBannerMetric(
                        label: 'View',
                        value: 'Inc. Deleted',
                        icon: Icons.delete_outline,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.l),

                // Operational Status / Network Alerts
                if (!state.accessible)
                  AppBannerAlert(
                    message: peopleFailure(state.failure),
                    type: AppStatusType.danger,
                  )
                else if (!state.online && state.synchronizedAt != null)
                  AppBannerAlert(
                    message:
                        'Offline — last synchronized ${state.synchronizedAt!.toLocal()}. Read-only.',
                    type: AppStatusType.warning,
                  )
                else if (!state.realtimeConnected && state.online)
                  const AppBannerAlert(
                    message:
                        'Live updates reconnecting. Checking for changes periodically.',
                    type: AppStatusType.info,
                  ),
                if (state.online && !state.writable)
                  const AppBannerAlert(
                    message: 'Event is read-only.',
                    type: AppStatusType.warning,
                  ),
                if (state.load == PeopleLoad.error)
                  AppBannerAlert(
                    message: peopleFailure(state.failure),
                    type: AppStatusType.danger,
                  ),

                // Search & Filters Surface
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: state.query,
                        key: const ValueKey('people-search'),
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Search names, phones or notes',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.secondaryText,
                          ),
                          counterText: '',
                        ),
                        onChanged: controller.search,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Show deleted people',
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                        value: state.deleted,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            controller.search(state.query, deleted: v),
                      ),
                      const SizedBox(height: AppSpace.s),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: state.canWrite
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => PersonEditor(
                                          controller: controller,
                                        ),
                                      ),
                                    )
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add person'),
                            ),
                          ),
                          const SizedBox(width: AppSpace.m),
                          OutlinedButton.icon(
                            onPressed: controller.reconcile,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh / Retry'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                AppSpace.touch,
                                AppSpace.touch,
                              ),
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderRadiusS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading bar indicator
          if (state.load == PeopleLoad.loading)
            const LinearProgressIndicator(
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
            ),

          // Content Area
          Expanded(
            child: state.load == PeopleLoad.empty
                ? AppEmptyState(
                    message: state.query.isNotEmpty
                        ? 'No matching people.'
                        : state.deleted
                        ? 'No deleted people.'
                        : 'No people yet. Add the first person.',
                    icon: Icons.people_outline,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                    itemCount: state.rows.length,
                    itemBuilder: (context, i) {
                      final p = state.rows[i];
                      final isDeleted = p.isDeleted;
                      final isActive = p.status == PersonStatus.active;
                      return AppListRow(
                        key: ValueKey(p.id),
                        title: BidiTextFormatter.isolate(p.displayName),
                        subtitle:
                            '${BidiTextFormatter.isolate(p.phone.isEmpty ? 'Phone not entered' : p.phone)} · ${isActive ? 'Active' : 'Inactive'}',
                        leadingIcon: isDeleted
                            ? Icons.person_off_outlined
                            : Icons.person_outline,
                        isDeleted: isDeleted,
                        statusChip: isDeleted
                            ? const AppStatusChip(
                                label: 'Deleted',
                                type: AppStatusType.deleted,
                              )
                            : AppStatusChip(
                                label: isActive ? 'Active' : 'Inactive',
                                type: isActive
                                    ? AppStatusType.active
                                    : AppStatusType.inactive,
                              ),
                        onTap: state.online
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => PersonDetails(
                                    controller: controller,
                                    id: p.id,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),

          // Pagination Controls
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.l,
              vertical: AppSpace.s,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: state.page > 0
                      ? () => controller.page(state.page - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Previous'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                  child: Text(
                    'Page ${state.page + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: state.hasNext
                      ? () => controller.page(state.page + 1)
                      : null,
                  label: const Text('Next'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
