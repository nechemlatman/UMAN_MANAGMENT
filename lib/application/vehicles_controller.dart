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
  VehiclesController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  })  : explicitEventId = null,
        super(const VehiclesState());

  VehiclesController.forEvent(
    this.repository,
    this.explicitEventId,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const VehiclesState());

  final TransportRepository repository;
  final String? explicitEventId;
  final EventController events;
  final Duration pollInterval;

  StreamSubscription<EventState>? _events;
  Timer? _poll, _search;
  Future<void>? _refreshing, _closing;
  bool _started = false, _stopped = false, _again = false;
  bool _denied = false;
  int _generation = 0;
  String? _selectedVehicleId;

  bool get _access =>
      events.state.authenticated &&
      events.state.capabilities(_eventId).event != null &&
      !events.state.capabilities(_eventId).event!.isDeleted &&
      events.state.failure != CloudFailureKind.unauthorized;

  String get _eventId => explicitEventId ?? events.state.events.first.id;

  void start() {
    if (_started || _stopped) return;
    _started = true;
    _events = events.stream.listen((_) => _onEventStateChanged());
    _onEventStateChanged();
  }

  void _onEventStateChanged() {
    if (_stopped) return;
    final cap = events.state.capabilities(_eventId);
    final access = _access;
    final online = events.state.online;
    final writable = cap.canEdit;

    if (!access) {
      if (!_denied) {
        _denied = true;
        emit(
          state.copyWith(
            load: VehiclesLoad.error,
            accessible: false,
            online: online,
            writable: false,
            realtimeConnected: false,
            failure: CloudFailureKind.unauthorized,
          ),
        );
      }
      return;
    }

    _denied = false;
    final currentOnline = state.online;
    emit(
      state.copyWith(
        accessible: true,
        online: online,
        writable: writable,
      ),
    );

    if (!currentOnline && online) {
      refresh();
    } else if (state.load == VehiclesLoad.initial) {
      refresh();
    }
  }

  void updateQuery(String text) {
    if (_stopped) return;
    _search?.cancel();
    emit(state.copyWith(query: text));
    _search = Timer(const Duration(milliseconds: 300), refresh);
  }

  void toggleIncludeDeleted() {
    if (_stopped) return;
    emit(state.copyWith(deleted: !state.deleted));
    refresh();
  }

  void selectVehicle(Vehicle? vehicle) {
    _selectedVehicleId = vehicle?.id;
    emit(state.copyWith(selectedVehicle: vehicle, clearSelectedVehicle: vehicle == null));
  }

  Future<void> refresh() {
    if (_closing != null) return _closing!;
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    final gen = ++_generation;
    final completer = Completer<void>();
    _refreshing = completer.future;

    Future<void>(() async {
      try {
        if (!_access) return;
        if (state.load == VehiclesLoad.initial) {
          emit(state.copyWith(load: VehiclesLoad.loading));
        }

        final vehicles = await repository.listVehicles(
          _eventId,
          query: state.query,
          includeDeleted: state.deleted,
        );

        if (gen != _generation || _stopped) return;

        Vehicle? selected;
        if (_selectedVehicleId != null) {
          try {
            selected = vehicles.firstWhere((v) => v.id == _selectedVehicleId);
          } catch (_) {
            selected = await repository.readVehicle(_eventId, _selectedVehicleId!);
          }
        }

        emit(
          state.copyWith(
            vehicles: vehicles,
            load: vehicles.isEmpty ? VehiclesLoad.empty : VehiclesLoad.data,
            synchronizedAt: DateTime.now().toUtc(),
            selectedVehicle: selected,
            clearSelectedVehicle: selected == null && _selectedVehicleId == null,
          ),
        );
      } catch (e) {
        if (gen != _generation || _stopped) return;
        emit(
          state.copyWith(
            load: VehiclesLoad.error,
            failure: CloudFailureKind.unknown,
          ),
        );
      } finally {
        _refreshing = null;
        completer.complete();
        if (_again && !_stopped) {
          _again = false;
          refresh();
        }
      }
    });

    return _refreshing!;
  }

  Future<bool> saveVehicle(
    VehicleInput input, {
    required String requestId,
    Vehicle? base,
  }) async {
    if (!state.canWrite) return false;
    emit(state.copyWith(save: SaveStatus.saving));

    try {
      final vehicleId = await repository.saveVehicle(
        _eventId,
        input,
        requestId: requestId,
        id: base?.id,
        expectedVersion: base?.version,
      );

      emit(state.copyWith(save: SaveStatus.synced));
      _selectedVehicleId = vehicleId;
      await refresh();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          save: SaveStatus.failed,
          failure: CloudFailureKind.unknown,
        ),
      );
      return false;
    }
  }

  Future<bool> deleteVehicle(Vehicle vehicle) async {
    if (!state.canWrite) return false;
    emit(state.copyWith(save: SaveStatus.saving));

    try {
      await repository.deleteVehicle(
        _eventId,
        vehicle.id,
        expectedVersion: vehicle.version,
      );
      emit(state.copyWith(save: SaveStatus.synced));
      if (_selectedVehicleId == vehicle.id) {
        _selectedVehicleId = null;
      }
      await refresh();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          save: SaveStatus.failed,
          failure: CloudFailureKind.unknown,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    if (_stopped) return;
    _stopped = true;
    _search?.cancel();
    _poll?.cancel();
    await _events?.cancel();
    _closing = super.close();
    await _closing;
  }
}
