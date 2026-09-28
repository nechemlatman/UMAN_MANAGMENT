import 'package:flutter/material.dart';
import '../../application/accommodation_controller.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/repositories/event_repository.dart';
import '../design_system.dart';

String accommodationBidi(String value) => BidiTextFormatter.isolate(value);
String accommodationKindLabel(AccommodationKind kind) => switch (kind) {
  AccommodationKind.apartment => 'apartment',
  AccommodationKind.room => 'room',
  AccommodationKind.sleepingPlace => 'sleeping place',
  AccommodationKind.assignment => 'assignment',
};
Widget accommodationWarning(BuildContext context, String message) => Card(
  color: Theme.of(context).colorScheme.errorContainer,
  child: Padding(
    padding: const EdgeInsets.all(AppSpace.m),
    child: Text(
      '⚠ $message',
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  ),
);

class AccommodationFeedback extends StatelessWidget {
  const AccommodationFeedback({super.key, required this.state});
  final AccommodationState state;
  @override
  Widget build(BuildContext context) {
    if (state.online && state.failure == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpace.m),
      child: Text(switch (state.failure) {
        CloudFailureKind.conflict =>
          'Record changed. Your draft is preserved. Go back and reopen the latest record before saving.',
        CloudFailureKind.unauthorized => 'Access is no longer available.',
        CloudFailureKind.invalid =>
          'Check the entered values and referenced records.',
        CloudFailureKind.unavailable =>
          'Server unavailable. Review the latest record after reconnecting before retrying an uncertain save.',
        CloudFailureKind.unknown =>
          'The operation could not be completed. Refresh and retry.',
        null =>
          'Offline. Displayed records may be stale; reconnect before editing.',
      }),
    );
  }
}
