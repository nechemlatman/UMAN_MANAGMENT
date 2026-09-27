import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/accommodation.dart';
import '../domain/repositories/accommodation_repository.dart';
import '../domain/repositories/event_repository.dart';
import 'event_controller.dart';

class AccommodationState {
  const AccommodationState({
    this.data = const AccommodationSnapshot(),
    this.loading = true,
    this.online = false,
    this.writable = false,
    this.realtimeConnected = false,
    this.save = SaveStatus.idle,
    this.failure,
  });
  final AccommodationSnapshot data;
  final bool loading, online, writable, realtimeConnected;
  final SaveStatus save;
  final CloudFailureKind? failure;
  bool get canWrite => online && writable && save != SaveStatus.saving;
  AccommodationState copy({
    AccommodationSnapshot? data,
    bool? loading,
    bool? online,
    bool? writable,
    bool? realtimeConnected,
    SaveStatus? save,
    CloudFailureKind? failure,
    bool clearFailure = false,
  }) => AccommodationState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    online: online ?? this.online,
    writable: writable ?? this.writable,
    realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    save: save ?? this.save,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class AccommodationController extends Cubit<AccommodationState> {
  AccommodationController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const AccommodationState());
  final AccommodationRepository repository;
  final EventController events;
  final Duration pollInterval;
  StreamSubscription<RepositorySignal>? _signals;
  StreamSubscription<EventState>? _events;
  Timer? _poll;
  Future<void>? _refreshing, _closing;
  bool _stopped = false, _started = false, _again = false;
  int _generation = 0;
  bool get _access =>
      events.state.authenticated &&
      events.state.capabilities(repository.eventId).event != null &&
      !events.state.capabilities(repository.eventId).event!.isDeleted &&
      events.state.failure != CloudFailureKind.unauthorized;
  void _emit(AccommodationState value) {
    if (!_stopped) emit(value);
  }

  void _clear() {
    _generation++;
    _emit(
      const AccommodationState(
        loading: false,
        failure: CloudFailureKind.unauthorized,
      ),
    );
    unawaited(_signals?.cancel());
    _signals = null;
  }

  Future<void> start() async {
    if (_started || _stopped) return;
    _started = true;
    _events = events.stream.listen((_) {
      if (!_access) {
        _clear();
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
    if (!_access || _signals != null || _stopped) return;
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
      try {
        final data = await repository.read();
        if (_stopped || generation != _generation || !_access) continue;
        _emit(
          state.copy(
            data: data,
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
    _emit(state.copy(save: SaveStatus.idle, clearFailure: true));
  }

  Future<bool> save(
    AccommodationInput input, {
    required String requestId,
    AccommodationRecord? base,
  }) => _mutate(() async {
    await repository.save(input, requestId: requestId, base: base);
  });
  Future<bool> setDeleted(AccommodationRecord base, bool deleted) =>
      _mutate(() => repository.setDeleted(base, deleted));
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
      if (_stopped ||
          !_access ||
          state.failure == CloudFailureKind.unauthorized) {
        return false;
      }
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
    await _events?.cancel();
    await _signals?.cancel();
    await repository.dispose();
  }
}
