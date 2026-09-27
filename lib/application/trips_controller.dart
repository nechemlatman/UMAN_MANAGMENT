import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/trip.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/trips_repository.dart';
import 'event_controller.dart';

class TripsState {
  const TripsState({
    this.trips = const [],
    this.passengers = const [],
    this.options = const {},
    this.selected,
    this.query = '',
    this.deleted = false,
    this.deletedPassengers = false,
    this.loading = true,
    this.online = false,
    this.writable = false,
    this.realtimeConnected = false,
    this.save = SaveStatus.idle,
    this.failure,
  });
  final List<Trip> trips;
  final List<TripPassenger> passengers;
  final Map<String, List<TripAssignmentOption>> options;
  final Trip? selected;
  final String query;
  final bool deleted,
      deletedPassengers,
      loading,
      online,
      writable,
      realtimeConnected;
  final SaveStatus save;
  final CloudFailureKind? failure;
  bool get canWrite => online && writable && save != SaveStatus.saving;
  TripsState copy({
    List<Trip>? trips,
    List<TripPassenger>? passengers,
    Map<String, List<TripAssignmentOption>>? options,
    Trip? selected,
    bool clearSelected = false,
    String? query,
    bool? deleted,
    bool? deletedPassengers,
    bool? loading,
    bool? online,
    bool? writable,
    bool? realtimeConnected,
    SaveStatus? save,
    CloudFailureKind? failure,
    bool clearFailure = false,
  }) => TripsState(
    trips: trips ?? this.trips,
    passengers: passengers ?? this.passengers,
    options: options ?? this.options,
    selected: clearSelected ? null : selected ?? this.selected,
    query: query ?? this.query,
    deleted: deleted ?? this.deleted,
    deletedPassengers: deletedPassengers ?? this.deletedPassengers,
    loading: loading ?? this.loading,
    online: online ?? this.online,
    writable: writable ?? this.writable,
    realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    save: save ?? this.save,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class TripsController extends Cubit<TripsState> {
  TripsController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const TripsState());
  final TripsRepository repository;
  final EventController events;
  final Duration pollInterval;
  StreamSubscription<RepositorySignal>? _signals;
  StreamSubscription<EventState>? _events;
  Timer? _poll, _search;
  Future<void>? _refreshing, _closing;
  bool _stopped = false, _started = false, _again = false;
  int _generation = 0;
  String? _selectedId;
  bool get _access =>
      events.state.authenticated &&
      events.state.capabilities(repository.eventId).event != null &&
      !events.state.capabilities(repository.eventId).event!.isDeleted &&
      events.state.failure != CloudFailureKind.unauthorized;
  void _emit(TripsState value) {
    if (!_stopped) emit(value);
  }

  void _clear() {
    _generation++;
    _selectedId = null;
    _emit(TripsState(loading: false, failure: CloudFailureKind.unauthorized));
  }

  Future<void> start() async {
    if (_started || _stopped) return;
    _started = true;
    _events = events.stream.listen((_) {
      if (!_access) {
        _clear();
        unawaited(_signals?.cancel());
        _signals = null;
      } else {
        _listen();
        unawaited(refresh());
      }
    });
    _listen();
    _poll = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    await refresh();
  }

  void _listen() {
    if (!_access || _signals != null) return;
    _signals = repository.signals.listen((signal) {
      _emit(
        state.copy(
          realtimeConnected: signal == RepositorySignal.connected
              ? true
              : signal == RepositorySignal.disconnected
              ? false
              : null,
        ),
      );
      if (signal != RepositorySignal.disconnected) unawaited(refresh());
    });
  }

  void updateQuery(String value) {
    _generation++;
    _emit(state.copy(query: value, trips: [], loading: true));
    _search?.cancel();
    _search = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(refresh()),
    );
  }

  void toggleDeleted() {
    _generation++;
    _emit(state.copy(deleted: !state.deleted));
    unawaited(refresh());
  }

  void toggleDeletedPassengers() {
    _generation++;
    _emit(state.copy(deletedPassengers: !state.deletedPassengers));
    unawaited(refresh());
  }

  void select(Trip? trip) {
    _generation++;
    _selectedId = trip?.id;
    _emit(
      state.copy(selected: trip, clearSelected: trip == null, passengers: []),
    );
    unawaited(refresh());
  }

  Future<void> refresh() {
    if (_stopped) return Future.value();
    if (!_access) {
      _clear();
      return Future.value();
    }
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    return _refreshing = _read().whenComplete(() => _refreshing = null);
  }

  Future<void> _read() async {
    do {
      _again = false;
      final generation = _generation;
      final selectedId = _selectedId;
      try {
        final trips = await repository.listTrips(
          query: state.query,
          deleted: state.deleted,
        );
        final options = await repository.assignmentOptions();
        final selected = selectedId == null
            ? null
            : await repository.readTrip(selectedId);
        final passengers = selected == null
            ? <TripPassenger>[]
            : await repository.listPassengers(
                selected.id,
                deleted: state.deletedPassengers,
              );
        if (_stopped || generation != _generation || !_access) continue;
        _emit(
          state.copy(
            trips: List.unmodifiable(trips),
            options: options,
            selected: selected,
            clearSelected: selected == null,
            passengers: List.unmodifiable(passengers),
            loading: false,
            online: true,
            writable: events.state.capabilities(repository.eventId).canEdit,
            clearFailure:
                state.save != SaveStatus.conflict &&
                state.save != SaveStatus.failed,
          ),
        );
      } catch (e) {
        if (_stopped || generation != _generation) continue;
        final kind = e is CloudFailure ? e.kind : CloudFailureKind.unknown;
        if (kind == CloudFailureKind.unauthorized) {
          _clear();
        } else {
          _emit(
            state.copy(
              loading: false,
              online: false,
              writable: false,
              failure: kind,
            ),
          );
        }
      }
    } while (_again && !_stopped && _access);
  }

  void beginEdit() {
    if (!_stopped) _emit(state.copy(save: SaveStatus.idle, clearFailure: true));
  }

  Future<bool> saveTrip(
    TripInput input, {
    required String requestId,
    Trip? base,
  }) => _mutate(() async {
    _selectedId = await repository.saveTrip(
      input,
      requestId: requestId,
      base: base,
    );
  });
  Future<bool> savePassenger(
    TripPassengerInput input, {
    required String requestId,
    TripPassenger? base,
  }) => _mutate(() async {
    await repository.savePassenger(input, requestId: requestId, base: base);
  });
  Future<bool> setTripDeleted(Trip base, bool deleted) =>
      _mutate(() => repository.setTripDeleted(base, deleted));
  Future<bool> setPassengerDeleted(TripPassenger base, bool deleted) =>
      _mutate(() => repository.setPassengerDeleted(base, deleted));
  Future<bool> _mutate(Future<void> Function() action) async {
    if (_stopped || !_access || !state.canWrite) return false;
    _emit(state.copy(save: SaveStatus.saving, clearFailure: true));
    try {
      await action();
      await refresh();
      if (_stopped ||
          !_access ||
          state.failure == CloudFailureKind.unauthorized) {
        return false;
      }
      _emit(state.copy(save: SaveStatus.synced));
      return true;
    } catch (e) {
      await refresh();
      final kind = e is CloudFailure ? e.kind : CloudFailureKind.unknown;
      if (kind == CloudFailureKind.unauthorized) _clear();
      _emit(
        state.copy(
          save: kind == CloudFailureKind.conflict
              ? SaveStatus.conflict
              : SaveStatus.failed,
          failure: kind,
          online: kind == CloudFailureKind.unavailable ? false : null,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() => _closing ??= _close().then((_) => super.close());
  Future<void> _close() async {
    _stopped = true;
    _generation++;
    _poll?.cancel();
    _search?.cancel();
    await _events?.cancel();
    await _signals?.cancel();
    await repository.dispose();
  }
}
