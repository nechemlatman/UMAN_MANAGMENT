import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/event.dart';
import '../domain/repositories/event_repository.dart';

enum SaveStatus { idle, saving, synced, failed, conflict }

class EventState {
  const EventState({
    this.events = const [],
    this.online = false,
    this.synchronizedAt,
    this.saveStatus = SaveStatus.idle,
    this.failure,
  });
  final List<Event> events;
  final bool online;
  final DateTime? synchronizedAt;
  final SaveStatus saveStatus;
  final CloudFailureKind? failure;
  bool get canEdit => online && saveStatus != SaveStatus.saving;
}

class EventController extends Cubit<EventState> {
  EventController(
    this.repository,
    this.cache, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const EventState());
  final EventRepository repository;
  final EventCache cache;
  final Duration pollInterval;
  StreamSubscription<RepositorySignal>? _subscription;
  Timer? _timer;
  Future<void>? _refreshing;
  Future<void>? _closing;
  bool _again = false, _stopped = false, _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    EventSnapshot? snapshot;
    try {
      snapshot = await cache.read();
    } catch (_) {
      // A disposable cache must not prevent loading the canonical server state.
    }
    if (_stopped) return;
    if (snapshot != null &&
        EventSnapshot.isTimestampUsable(
          snapshot.synchronizedAt,
          DateTime.now().toUtc(),
        )) {
      emit(
        EventState(
          events: snapshot.events,
          synchronizedAt: snapshot.synchronizedAt,
        ),
      );
    }
    _subscription = repository.signals.listen((signal) {
      if (_stopped) return;
      if (signal == RepositorySignal.disconnected) {
        _setOffline();
      } else {
        unawaited(reconcile());
      }
    });
    _timer = Timer.periodic(pollInterval, (_) => unawaited(reconcile()));
    await reconcile();
  }

  void _set({
    List<Event>? events,
    bool? online,
    DateTime? at,
    SaveStatus? save,
    CloudFailureKind? failure,
    bool clearSnapshot = false,
  }) {
    if (_stopped) return;
    emit(
      EventState(
        events: clearSnapshot ? const [] : events ?? state.events,
        online: online ?? state.online,
        synchronizedAt: clearSnapshot ? null : at ?? state.synchronizedAt,
        saveStatus: save ?? state.saveStatus,
        failure: failure,
      ),
    );
  }

  void _setOffline([CloudFailureKind? failure]) {
    _set(
      online: false,
      failure: failure,
      clearSnapshot: !EventSnapshot.isTimestampUsable(
        state.synchronizedAt,
        DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> reconcile() {
    if (_stopped) return Future.value();
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    final future = _readLoop();
    _refreshing = future;
    return future.whenComplete(() {
      _refreshing = null;
    });
  }

  Future<void> _readLoop() async {
    do {
      _again = false;
      try {
        final events = await repository.readAll();
        if (_stopped) return;
        final snapshot = EventSnapshot(events, DateTime.now().toUtc());
        _set(
          events: snapshot.events,
          online: true,
          at: snapshot.synchronizedAt,
        );
        try {
          await cache.write(snapshot);
        } catch (_) {
          /* Online state remains valid. */
        }
      } on CloudFailure catch (error) {
        if (_stopped) return;
        if (error.kind == CloudFailureKind.unauthorized) {
          // Revoke visible access immediately, even if secure storage is slow.
          _set(online: false, failure: error.kind, clearSnapshot: true);
          try {
            await cache.clear();
          } catch (_) {}
        } else {
          _setOffline(error.kind);
        }
      } catch (_) {
        _setOffline(CloudFailureKind.unknown);
      }
    } while (_again && !_stopped);
  }

  Future<bool> rename(Event base, String draft) =>
      _mutate(() => repository.rename(base.id, base.version, draft));
  Future<bool> create(NewEvent input) =>
      _mutate(() => repository.create(input));
  Future<bool> _mutate(Future<Event> Function() action) async {
    if (!state.canEdit || _stopped) return false;
    _set(save: SaveStatus.saving);
    try {
      await action();
      if (_stopped) return false;
      await reconcile();
      _set(save: SaveStatus.synced);
      return true;
    } on CloudFailure catch (error) {
      await reconcile();
      _set(
        save: error.kind == CloudFailureKind.conflict
            ? SaveStatus.conflict
            : SaveStatus.failed,
        failure: error.kind,
      );
      return false;
    } catch (_) {
      await reconcile();
      _set(save: SaveStatus.failed, failure: CloudFailureKind.unknown);
      return false;
    }
  }

  @override
  Future<void> close() => _closing ??= _closeSession().then((_) => super.close());

  Future<void> _closeSession() async {
    _stopped = true;
    _timer?.cancel();
    await _subscription?.cancel();
    await _refreshing;
    await repository.dispose();
  }
}
