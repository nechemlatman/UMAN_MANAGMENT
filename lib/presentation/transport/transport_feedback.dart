import 'package:flutter/material.dart';
import '../../domain/repositories/event_repository.dart';
import '../design_system.dart';

class TransportFeedback extends StatelessWidget {
  const TransportFeedback({
    super.key,
    required this.failure,
    required this.online,
  });
  final CloudFailureKind? failure;
  final bool online;
  @override
  Widget build(BuildContext context) {
    if (failure == null && online) return const SizedBox.shrink();
    final message = switch (failure) {
      CloudFailureKind.conflict =>
        'Record changed. Your draft is preserved. Go back and reopen the latest record before saving.',
      CloudFailureKind.unauthorized => 'Access is no longer available.',
      CloudFailureKind.invalid => 'Check the entered values.',
      CloudFailureKind.unavailable =>
        'Server unavailable. The save outcome may be uncertain. Reconnect and review the latest record before retrying.',
      CloudFailureKind.unknown =>
        'The operation could not be completed. Retry after refreshing.',
      null => 'Offline. Reconnect before making changes.',
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpace.m),
      child: Text(message),
    );
  }
}
