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

enum RepositorySignal { changed, connected, disconnected }

abstract interface class EventRepository {
  Stream<RepositorySignal> get signals;
  Future<List<Event>> readAll();
  Future<Event> create(NewEvent input);
  Future<Event> rename(String id, int expectedVersion, String name);
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
