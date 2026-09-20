import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/event.dart';
import '../domain/entities/flight.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/flights_repository.dart';
import 'event_controller.dart';

enum FlightsLoad { initial, loading, data, empty, error }

class FlightsState {
  const FlightsState({
    this.flights = const [],
    this.load = FlightsLoad.initial,
    this.deleted = false,
    this.online = false,
    this.accessible = true,
    this.writable = false,
    this.realtimeConnected = false,
    this.synchronizedAt,
    this.save = SaveStatus.idle,
    this.failure,
    this.selectedFlight,
    this.passengers = const [],
  });

  final List<Flight> flights;
  final FlightsLoad load;
  final bool deleted, online, accessible, writable, realtimeConnected;
  final DateTime? synchronizedAt;
  final SaveStatus save;
  final CloudFailureKind? failure;
  final Flight? selectedFlight;
  final List<FlightPassenger> passengers;

  bool get canWrite =>
      accessible && online && writable && save != SaveStatus.saving;

  FlightsState copyWith({
    List<Flight>? flights,
    FlightsLoad? load,
    bool? deleted,
    bool? online,
    bool? accessible,
    bool? writable,
    bool? realtimeConnected,
    DateTime? synchronizedAt,
    SaveStatus? save,
    CloudFailureKind? failure,
    Flight? selectedFlight,
    List<FlightPassenger>? passengers,
    bool clearSelectedFlight = false,
  }) {
    return FlightsState(
      flights: flights ?? this.flights,
      load: load ?? this.load,
      deleted: deleted ?? this.deleted,
      online: online ?? this.online,
      accessible: accessible ?? this.accessible,
      writable: writable ?? this.writable,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
      synchronizedAt: synchronizedAt ?? this.synchronizedAt,
      save: save ?? this.save,
      failure: failure,
      selectedFlight: clearSelectedFlight ? null : selectedFlight ?? this.selectedFlight,
      passengers: passengers ?? this.passengers,
    );
  }
}

class FlightsController extends Cubit<FlightsState> {
  FlightsController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const FlightsState());

  final FlightsRepository repository;
  final EventController events;
  final Duration pollInterval;

  StreamSubscription<RepositorySignal>? _signals;
  StreamSubscription<EventState>? _events;
  Timer? _poll;
  Future<void>? _refreshing, _closing;
  bool _started = false, _stopped = false, _again = false;
  bool _denied = false;
  int _generation = 0;
  String? _selectedFlightId;

  bool get _access =>
      events.state.authenticated &&
      events.state.capabilities(repository.eventId).event != null &&
      !events.state.capabilities(repository.eventId).event!.isDeleted &&
      events.state.failure != CloudFailureKind.unauthorized;

  bool get _writable =>
      _access &&
      events.state.online &&
      events.state.capabilities(repository.eventId).event!.lifecycleStage !=
          EventLifecycleStage.archived;

  void _set({
    List<Flight>? flights,
    FlightsLoad? load,
    bool? deleted,
    bool? online,
    bool? realtime,
    SaveStatus? save,
    CloudFailureKind? failure,
    Flight? selectedFlight,
    List<FlightPassenger>? passengers,
    bool clearSelectedFlight = false,
    bool clear = false,
    DateTime? at,
  }) {
    if (_stopped) return;
    emit(state.copyWith(
      flights: clear ? const [] : flights,
      load: load,
      deleted: deleted,
      online: online ?? (_access && !_denied),
      accessible: _access && !_denied,
      writable: _writable,
      realtimeConnected: realtime,
      synchronizedAt: clear ? null : at,
      save: save,
      failure: failure,
      selectedFlight: selectedFlight,
      passengers: clear ? const [] : passengers,
      clearSelectedFlight: clearSelectedFlight || clear,
    ));
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _events = events.stream.listen((_) {
      if (!_access) {
        _generation++;
        _selectedFlightId = null;
        _set(
          clear: true,
          online: false,
          load: FlightsLoad.error,
          failure: CloudFailureKind.unauthorized,
        );
      } else {
        _set();
        unawaited(reconcile());
      }
    });
    _signals = repository.signals.listen((signal) {
      if (signal == RepositorySignal.disconnected) {
        _set(realtime: false);
      } else {
        if (signal == RepositorySignal.connected) _set(realtime: true);
        unawaited(reconcile());
      }
    });
    _poll = Timer.periodic(pollInterval, (_) => unawaited(reconcile()));
    await reconcile();
  }

  Future<void> selectFlight(String? id) async {
    _selectedFlightId = id;
    _generation++;
    _set(clearSelectedFlight: true, passengers: []);
    if (id != null) await reconcile();
  }

  void toggleDeleted() {
    _generation++;
    _set(deleted: !state.deleted, load: FlightsLoad.loading, flights: []);
    unawaited(reconcile());
  }

  Future<void> reconcile() {
    if (_stopped || !_access) return Future.value();
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    _refreshing = _readLoop().whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  Future<void> _readLoop() async {
    do {
      _again = false;
      final generation = _generation;
      final selectedId = _selectedFlightId;
      if (state.load == FlightsLoad.initial) _set(load: FlightsLoad.loading);
      try {
        final flights = await repository.listFlights(
          repository.eventId,
          includeDeleted: state.deleted,
        );
        Flight? selected;
        List<FlightPassenger> passengers = [];
        if (selectedId != null) {
          selected = await repository.readFlight(repository.eventId, selectedId);
          passengers = await repository.listFlightPassengers(repository.eventId, selectedId);
        }

        if (_stopped || generation != _generation || !_access) continue;
        
        _denied = false;
        _set(
          flights: List.unmodifiable(flights),
          online: true,
          at: DateTime.now().toUtc(),
          selectedFlight: selected,
          passengers: List.unmodifiable(passengers),
          load: flights.isEmpty ? FlightsLoad.empty : FlightsLoad.data,
        );
      } on CloudFailure catch (error) {
        if (_stopped || generation != _generation) continue;
        _denied = error.kind == CloudFailureKind.unauthorized;
        _set(
          online: false,
          load: FlightsLoad.error,
          failure: error.kind,
          clear: _denied,
          clearSelectedFlight: true,
        );
      } catch (_) {
        if (_stopped || generation != _generation) continue;
        _set(
          online: false,
          load: FlightsLoad.error,
          failure: CloudFailureKind.unknown,
          clearSelectedFlight: true,
        );
      }
    } while (_again && !_stopped && _access);
  }

  Future<bool> saveFlight(
    FlightInput input, {
    required String requestId,
    Flight? base,
  }) =>
      _mutate(() async {
        await repository.saveFlight(
          eventId: repository.eventId,
          flightId: base?.id,
          expectedVersion: base?.version,
          fields: input,
          requestId: requestId,
        );
      });

  Future<bool> setFlightDeleted(Flight base, bool deleted) =>
      _mutate(() => repository.setFlightDeleted(
            eventId: repository.eventId,
            flightId: base.id,
            expectedVersion: base.version,
            deleted: deleted,
          ));

  Future<bool> savePassenger(
    FlightPassengerInput input, {
    required String requestId,
    FlightPassenger? base,
  }) =>
      _mutate(() async {
        await repository.saveFlightPassenger(
          eventId: repository.eventId,
          passengerId: base?.id,
          expectedVersion: base?.version,
          fields: input,
          requestId: requestId,
        );
      });

  Future<bool> removePassenger(FlightPassenger base) =>
      _mutate(() => repository.setFlightPassengerDeleted(
            eventId: repository.eventId,
            passengerId: base.id,
            expectedVersion: base.version,
            deleted: true,
          ));

  Future<bool> _mutate(Future<void> Function() action) async {
    if (!state.canWrite || _stopped) return false;
    _set(save: SaveStatus.saving);
    try {
      await action();
      await reconcile();
      if (_stopped) return false;
      _set(save: SaveStatus.synced);
      return true;
    } catch (error) {
      await reconcile();
      final kind = error is CloudFailure ? error.kind : CloudFailureKind.unknown;
      if (kind == CloudFailureKind.unauthorized) _denied = true;
      _set(
        save: kind == CloudFailureKind.conflict ? SaveStatus.conflict : SaveStatus.failed,
        failure: kind,
        clear: kind == CloudFailureKind.unauthorized,
        online: kind == CloudFailureKind.unauthorized ? false : null,
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
    await _events?.cancel();
    await _signals?.cancel();
    await repository.dispose();
  }
}
