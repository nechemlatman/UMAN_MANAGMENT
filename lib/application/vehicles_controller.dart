import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/vehicle.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/transport_repository.dart';
import 'event_controller.dart';

enum VehiclesLoad { initial, loading, data, empty, error }

class VehiclesState {
  const VehiclesState({
    this.vehicles = const [],
    this.load = VehiclesLoad.initial,
    this.query = '',
    this.deleted = false,
    this.online = false,
    this.accessible = true,
    this.writable = false,
    this.realtimeConnected = false,
    this.synchronizedAt,
    this.save = SaveStatus.idle,
    this.failure,
    this.selectedVehicle,
  });

  final List<Vehicle> vehicles;
  final VehiclesLoad load;
  final String query;
  final bool deleted, online, accessible, writable, realtimeConnected;
  final DateTime? synchronizedAt;
  final SaveStatus save;
  final CloudFailureKind? failure;
  final Vehicle? selectedVehicle;

  bool get canWrite =>
      accessible && online && writable && save != SaveStatus.saving;

  VehiclesState copyWith({
    List<Vehicle>? vehicles,
    VehiclesLoad? load,
    String? query,
    bool? deleted,
    bool? online,
    bool? accessible,
    bool? writable,
    bool? realtimeConnected,
    DateTime? synchronizedAt,
    SaveStatus? save,
    CloudFailureKind? failure,
    Vehicle? selectedVehicle,
    bool clearSelectedVehicle = false,
  }) {
    return VehiclesState(
      vehicles: vehicles ?? this.vehicles,
      load: load ?? this.load,
      query: query ?? this.query,
      deleted: deleted ?? this.deleted,
      online: online ?? this.online,
      accessible: accessible ?? this.accessible,
      writable: writable ?? this.writable,
      realtimeConnected: realtimeConnected ?? this.realtimeConnected,
      synchronizedAt: synchronizedAt ?? this.synchronizedAt,
      save: save ?? this.save,
      failure: failure,
      selectedVehicle:
          clearSelectedVehicle ? null : selectedVehicle ?? this.selectedVehicle,
    );
  }
}

class VehiclesController extends Cubit<VehiclesState> {
  VehiclesController(this.repository, this.events,
      {this.pollInterval = const Duration(seconds: 20)}) : super(const VehiclesState());
  VehiclesController.forEvent(this.repository, String eventId, this.events,
      {this.pollInterval = const Duration(seconds: 20)}) : super(const VehiclesState()) {
    if (eventId != repository.eventId) throw ArgumentError('Transport event mismatch');
  }
  final TransportRepository repository;
  final EventController events;
  final Duration pollInterval;
  StreamSubscription<RepositorySignal>? _signals;
  StreamSubscription<EventState>? _events;
  Timer? _poll, _search;
  Future<void>? _refreshing, _closing;
  bool _started = false, _stopped = false, _again = false;
  int _generation = 0;
  String? _selectedId;
  String get _eventId => repository.eventId;
  bool get _access => events.state.authenticated &&
      events.state.capabilities(_eventId).event != null &&
      !events.state.capabilities(_eventId).event!.isDeleted &&
      events.state.failure != CloudFailureKind.unauthorized;

  void _set({List<Vehicle>? vehicles, VehiclesLoad? load, bool? online,
      bool? realtime, SaveStatus? save, CloudFailureKind? failure,
      Vehicle? selected, bool clearSelected = false, bool clear = false,
      DateTime? at}) {
    if (_stopped) return;
    emit(state.copyWith(
      vehicles: clear ? [] : vehicles, load: load,
      online: clear ? false : online,
      accessible: _access && !clear,
      writable: _access && events.state.capabilities(_eventId).canEdit,
      realtimeConnected: clear ? false : realtime,
      save: save, failure: failure ?? (state.save == SaveStatus.conflict || state.save == SaveStatus.failed ? state.failure : null),
      selectedVehicle: selected, clearSelectedVehicle: clear || clearSelected,
      synchronizedAt: at,
    ));
  }

  Future<void> start() async {
    if (_started || _stopped) return;
    _started = true;
    _events = events.stream.listen((_) {
      if (!_access) {
        _generation++;
        _selectedId = null;
        _set(clear: true, load: VehiclesLoad.error, failure: CloudFailureKind.unauthorized);
        unawaited(_signals?.cancel());
        _signals = null;
      } else {
        _listen();
        _set(online: state.online && events.state.online);
        unawaited(refresh());
      }
    });
    if (!_access) _set(clear: true, load: VehiclesLoad.error, failure: CloudFailureKind.unauthorized);
    _listen();
    _poll = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    await refresh();
  }

  void _listen() {
    if (!_access || _signals != null) return;
    _signals = repository.signals.listen((signal) {
      if (signal == RepositorySignal.disconnected) {
        _set(realtime: false);
      } else {
        if (signal == RepositorySignal.connected) _set(realtime: true);
        unawaited(refresh());
      }
    });
  }

  void updateQuery(String text) {
    if (_stopped) return;
    _generation++;
    emit(state.copyWith(query: text, vehicles: [], load: VehiclesLoad.loading));
    _search?.cancel();
    _search = Timer(const Duration(milliseconds: 300), () => unawaited(refresh()));
  }
  void toggleIncludeDeleted() {
    if (_stopped) return;
    _generation++;
    emit(state.copyWith(deleted: !state.deleted));
    unawaited(refresh());
  }
  void selectVehicle(Vehicle? value) {
    if (_stopped) return;
    _generation++;
    _selectedId = value?.id;
    _set(selected: value, clearSelected: value == null);
    unawaited(refresh());
  }
  Future<void> refresh() {
    if (_stopped || !_access) return Future.value();
    if (_refreshing != null) { _again = true; return _refreshing!; }
    _refreshing = _readLoop().whenComplete(() => _refreshing = null);
    return _refreshing!;
  }
  Future<void> _readLoop() async {
    do {
      _again = false;
      final generation = _generation;
      final selectedId = _selectedId;
      if (state.load == VehiclesLoad.initial) _set(load: VehiclesLoad.loading);
      try {
        final rows = await repository.listVehicles(_eventId,
          query: state.query, includeDeleted: state.deleted);
        final selected = selectedId == null ? null : await repository.readVehicle(_eventId, selectedId);
        if (_stopped || generation != _generation || !_access) continue;
        _set(vehicles: List.unmodifiable(rows), online: true, selected: selected,
          clearSelected: selected == null, at: DateTime.now().toUtc(),
          load: rows.isEmpty ? VehiclesLoad.empty : VehiclesLoad.data);
      } catch (error) {
        if (_stopped || generation != _generation || !_access) continue;
        final kind = error is CloudFailure ? error.kind : CloudFailureKind.unknown;
        _set(online: false, load: VehiclesLoad.error, failure: kind,
          clear: kind == CloudFailureKind.unauthorized, clearSelected: true);
      }
    } while (_again && !_stopped && _access);
  }
  Future<bool> saveVehicle(VehicleInput input, {required String requestId, Vehicle? base}) =>
      _mutate(() async {
        final id = await repository.saveVehicle(_eventId, input,
          requestId: requestId, id: base?.id, expectedVersion: base?.version);
        if (!_stopped) _selectedId = id;
      });
  Future<bool> deleteVehicle(Vehicle base) => _mutate(() => repository.deleteVehicle(
      _eventId, base.id, expectedVersion: base.version));
  Future<bool> restoreVehicle(Vehicle base) => _mutate(() => repository.restoreVehicle(
      _eventId, base.id, expectedVersion: base.version));
  void beginEdit() {
    if (!_stopped && state.save != SaveStatus.saving) emit(state.copyWith(save: SaveStatus.idle));
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_stopped || !_access || !state.canWrite) return false;
    emit(state.copyWith(save: SaveStatus.saving));
    try {
      await action();
      await refresh();
      if (_stopped || !_access) return false;
      _set(save: SaveStatus.synced);
      return true;
    } catch (error) {
      await refresh();
      final kind = error is CloudFailure ? error.kind : CloudFailureKind.unknown;
      _set(save: kind == CloudFailureKind.conflict ? SaveStatus.conflict : SaveStatus.failed,
        failure: kind, clear: kind == CloudFailureKind.unauthorized,
        online: kind == CloudFailureKind.unavailable ? false : null);
      return false;
    }
  }
  @override
  Future<void> close() => _closing ??= _close().then((_) => super.close());
  Future<void> _close() async {
    _stopped = true;
    _generation++;
    _poll?.cancel(); _search?.cancel();
    await _events?.cancel(); await _signals?.cancel();
    await repository.dispose();
  }
}
