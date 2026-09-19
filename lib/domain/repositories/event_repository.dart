import '../entities/event.dart';

enum CloudFailureKind { unavailable, unauthorized, conflict, invalid, unknown }

class CloudFailure implements Exception {
  const CloudFailure(this.kind);
  final CloudFailureKind kind;
}

class NewEvent {
  const NewEvent({
    required this.requestId,
    required this.name,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.baseCurrency,
  });
  final String requestId, name, startDate, endDate, baseCurrency;
  final int year;
}

/// Explicit editable fields; lifecycle, tombstones and settings are separate.
class EventDetailsInput {
  const EventDetailsInput({
    required this.name,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.baseCurrency,
    this.hebrewName,
    this.description,
    this.managerNotes,
  });
  final String name, startDate, endDate, baseCurrency;
  final String? hebrewName, description, managerNotes;
  final int year;
}

enum RepositorySignal { changed, connected, disconnected }

abstract interface class EventRepository {
  Stream<RepositorySignal> get signals;
  Future<List<Event>> readAll();
  Future<Event> create(NewEvent input);
  Future<Event> rename(String id, int expectedVersion, String name);
  Future<Event> editDetails(
    String id,
    int expectedVersion,
    EventDetailsInput input,
  );
  Future<Event> transition(
    String id,
    int expectedVersion,
    EventLifecycleStage stage,
  );
  Future<Event> archive(String id, int expectedVersion);
  Future<Event> softDelete(String id, int expectedVersion);
  Future<Event> restore(String id, int expectedVersion);
  Future<void> dispose();
}

class EventSnapshot {
  EventSnapshot(List<Event> events, this.synchronizedAt)
    : events = List.unmodifiable(events);
  final List<Event> events;
  final DateTime synchronizedAt;

  static const maximumAge = Duration(hours: 24);

  static bool isTimestampUsable(DateTime? timestamp, DateTime now) {
    if (timestamp == null) return false;
    final age = now.difference(timestamp);
    return !age.isNegative && age <= maximumAge;
  }
}

abstract interface class EventCache {
  Future<EventSnapshot?> read();
  Future<void> write(EventSnapshot snapshot);
  Future<void> clear();
}
