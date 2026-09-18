import 'foundation_failure.dart';

enum FoundationOperation { opening, opened, closing, closed, reading, writing }

/// The diagnostic API deliberately accepts no free text or exception objects.
final class FoundationDiagnostic {
  const FoundationDiagnostic(this.operation, [this.failure]);
  final FoundationOperation operation;
  final FoundationFailureKind? failure;

  @override
  String toString() => '${operation.name}:${failure?.name ?? "ok"}';
}

typedef DiagnosticSink = void Function(FoundationDiagnostic diagnostic);

void discardDiagnostic(FoundationDiagnostic diagnostic) {}
