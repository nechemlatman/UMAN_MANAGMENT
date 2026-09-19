import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/event.dart';
import '../design_system.dart';
import 'event_editor.dart';

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({
    super.key,
    required this.controller,
    required this.eventId,
  });
  final EventController controller;
  final String eventId;

  Future<void> confirm(
    BuildContext context,
    Event base,
    String title,
    String explanation,
    Future<bool> Function(Event) action,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final ok = await action(base);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Saved'
              : controller.state.saveStatus == SaveStatus.conflict
              ? 'Event changed. Review current details before trying again.'
              : 'Operation not confirmed. Check access, connection and current details.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EventController, EventState>(
    bloc: controller,
    builder: (context, state) {
      final capability = state.capabilities(eventId);
      final event = capability.event;
      return Scaffold(
        appBar: AppBar(title: const Text('Event details')),
        body: SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpace.formWidth),
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  if (event == null)
                    const Text(
                      'Event unavailable. Access may have been revoked, or no valid cached data is available.',
                    )
                  else ...[
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (!state.online)
                      Text(
                        'Offline — last synchronized ${state.synchronizedAt?.toLocal() ?? 'unknown'}',
                      ),
                    for (final pair in <(String, String?)>[
                      ('Hebrew name', event.hebrewName),
                      ('Description', event.description),
                      ('Manager notes', event.managerNotes),
                      ('Year', '${event.year}'),
                      ('Start date', '${event.startDate}'),
                      ('End date', '${event.endDate}'),
                      ('Base currency', event.baseCurrency),
                      ('Stage', event.lifecycleStage.storageValue),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.s,
                        ),
                        child: SelectableText(
                          '${pair.$1}: ${BidiTextFormatter.isolate(pair.$2 ?? 'Not entered')}',
                        ),
                      ),
                    if (event.isDeleted)
                      const Text(
                        'Soft-deleted. Records and membership are preserved.',
                      )
                    else if (event.lifecycleStage ==
                        EventLifecycleStage.archived)
                      const Text(
                        'Archived — read-only. Operational reopening is not permitted.',
                      ),
                    if (event.lifecycleStage == EventLifecycleStage.planning &&
                        !event.isDeleted)
                      const Text(
                        'Readiness advancement is unavailable until minimum setup requirements are defined.',
                      ),
                    const SizedBox(height: AppSpace.l),
                    FilledButton(
                      onPressed: capability.canEdit
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => EventEditor(
                                  controller: controller,
                                  base: event,
                                ),
                              ),
                            )
                          : null,
                      child: const Text('Edit event'),
                    ),
                    for (final target in capability.transitions)
                      TextButton(
                        onPressed: () => confirm(
                          context,
                          event,
                          'Change lifecycle?',
                          'Move this Event to ${target.storageValue}? This is an explicit manager action.',
                          (base) => controller.transition(base, target),
                        ),
                        child: Text('Move to ${target.storageValue}'),
                      ),
                    TextButton(
                      onPressed: capability.canArchive
                          ? () => confirm(
                              context,
                              event,
                              'Archive Event?',
                              'Archiving is final for operations. The Event will become read-only.',
                              controller.archive,
                            )
                          : null,
                      child: const Text('Archive event'),
                    ),
                    if (event.isDeleted)
                      TextButton(
                        onPressed: capability.canRestore
                            ? () => confirm(
                                context,
                                event,
                                'Restore Event?',
                                'Restore visibility without changing the lifecycle stage.',
                                controller.restore,
                              )
                            : null,
                        child: const Text('Restore event'),
                      )
                    else
                      TextButton(
                        onPressed: capability.canDelete
                            ? () => confirm(
                                context,
                                event,
                                'Soft-delete Event?',
                                'Hide this Event from the default list. Records remain stored and can be restored.',
                                controller.softDelete,
                              )
                            : null,
                        child: const Text('Soft-delete event'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
