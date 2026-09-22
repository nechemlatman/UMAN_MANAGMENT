import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/driver.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/transport_repository.dart';
import 'event_controller.dart';

enum DriversLoad { initial, loading, data, empty, error }

class DriversState {
  const DriversState({
    this.drivers = const [],
    this.load = DriversLoad.initial,
    this.query = '',
    this.deleted = false,
    this.online = false,
    this.accessible = true,
    this.writable = false,
    this.realtimeConnected = false,
    this.synchronizedAt,
    this.save = SaveStatus.idle,
    this.failure,
    this.selectedDriver,
  });

  final List<Driver> drivers;
  final DriversLoad load;
  final String query;
  final bool deleted, online, accessible, writable, realtimeConnected;
  final DateTime? synchronizedAt;
  final SaveStatus save;
  final CloudFailureKind? failure;
  final Driver? selectedDriver;

  bool get canWrite =>
      accessible && online && writable && save != SaveStatus.saving;

  DriversState copyWith({
    List<Driver>? drivers,
    DriversLoad? load,
    String? query,
    bool? deleted,
    bool? online,
    bool? accessible,
    bool? writable,
    bool? realtimeConnected,
    DateTime? synchronizedAt,
    SaveStatus? save,
    CloudFailureKind? failure,
    Driver? selectedDriver,
    bool clearSelectedDriver = false,
  }) {
    return DriversState(
      drivers: drivers ?? this.drivers,
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
      selectedDriver:
          clearSelectedDriver ? null : selectedDriver ?? this.selectedDriver,
    );
  }
}

class DriversController extends Cubit<DriversState> {
  DriversController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  })  : explicitEventId = null,
        super(const DriversState());

  DriversController.forEvent(
    this.repository,
    this.explicitEventId,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const DriversState());

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
  String? _selectedDriverId;

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
            load: DriversLoad.error,
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
    } else if (state.load == DriversLoad.initial) {
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

  void selectDriver(Driver? driver) {
    _selectedDriverId = driver?.id;
    emit(state.copyWith(selectedDriver: driver, clearSelectedDriver: driver == null));
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
        if (state.load == DriversLoad.initial) {
          emit(state.copyWith(load: DriversLoad.loading));
        }

        final drivers = await repository.listDrivers(
          _eventId,
          query: state.query,
          includeDeleted: state.deleted,
        );

        if (gen != _generation || _stopped) return;

        Driver? selected;
        if (_selectedDriverId != null) {
          try {
            selected = drivers.firstWhere((d) => d.id == _selectedDriverId);
          } catch (_) {
            selected = await repository.readDriver(_eventId, _selectedDriverId!);
          }
        }

        emit(
          state.copyWith(
            drivers: drivers,
            load: drivers.isEmpty ? DriversLoad.empty : DriversLoad.data,
            synchronizedAt: DateTime.now().toUtc(),
            selectedDriver: selected,
            clearSelectedDriver: selected == null && _selectedDriverId == null,
          ),
        );
      } catch (e) {
        if (gen != _generation || _stopped) return;
        emit(
          state.copyWith(
            load: DriversLoad.error,
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

  Future<bool> saveDriver(
    DriverInput input, {
    required String requestId,
    Driver? base,
  }) async {
    if (!state.canWrite) return false;
    emit(state.copyWith(save: SaveStatus.saving));

    try {
      final driverId = await repository.saveDriver(
        _eventId,
        input,
        requestId: requestId,
        id: base?.id,
        expectedVersion: base?.version,
      );

      emit(state.copyWith(save: SaveStatus.synced));
      _selectedDriverId = driverId;
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

  Future<bool> deleteDriver(Driver driver) async {
    if (!state.canWrite) return false;
    emit(state.copyWith(save: SaveStatus.saving));

    try {
      await repository.deleteDriver(
        _eventId,
        driver.id,
        expectedVersion: driver.version,
      );
      emit(state.copyWith(save: SaveStatus.synced));
      if (_selectedDriverId == driver.id) {
        _selectedDriverId = null;
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
