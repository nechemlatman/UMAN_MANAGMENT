enum FoundationFailureKind {
  databaseUnavailable,
  encryptionUnavailable,
  invalidKey,
  integrityFailure,
  storageFailure,
  unsupportedSchema,
}

/// Only a stable category crosses the infrastructure boundary, never SQL/data.
final class FoundationFailure implements Exception {
  const FoundationFailure(this.kind);
  final FoundationFailureKind kind;

  @override
  String toString() => 'FoundationFailure(${kind.name})';
}
