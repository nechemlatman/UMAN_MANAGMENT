import '../domain/entities/event.dart';

/// Advisory presentation policy. Only canonical RLS/RPC checks authorize writes.
class EventCapabilities {
  const EventCapabilities({
    required this.authenticated,
    required this.online,
    required this.saving,
    required this.hasMembership,
    this.event,
  });
  final bool authenticated, online, saving, hasMembership;
  final Event? event;
  bool get accessRevoked => authenticated && !hasMembership;
  bool get canCreate => authenticated && online && !saving && hasMembership;
  bool get readOnly =>
      !canCreate ||
      event == null ||
      event!.isDeleted ||
      event!.lifecycleStage == EventLifecycleStage.archived;
  bool get canEdit => !readOnly;
  bool get canArchive => !readOnly;
  bool get canDelete => !readOnly;
  bool get canRestore => canCreate && event != null && event!.isDeleted;
  List<EventLifecycleStage> get transitions => readOnly
      ? const []
      : switch (event!.lifecycleStage) {
          // Minimum setup is an unresolved product decision; do not invent readiness.
          EventLifecycleStage.planning => const [],
          EventLifecycleStage.ready => const [
            EventLifecycleStage.planning,
            EventLifecycleStage.travel,
          ],
          EventLifecycleStage.travel => const [EventLifecycleStage.inUman],
          EventLifecycleStage.inUman => const [EventLifecycleStage.departure],
          EventLifecycleStage.departure => const [EventLifecycleStage.closeout],
          _ => const [],
        };
  bool get canTransition => transitions.isNotEmpty;
}
