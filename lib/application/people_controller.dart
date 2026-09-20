import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/event.dart';
import '../domain/entities/person.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/people_repository.dart';
import 'event_controller.dart';

enum PeopleLoad { initial, loading, data, empty, error }

class PeopleState {
  const PeopleState({
    this.rows = const [],
    this.load = PeopleLoad.initial,
    this.query = '',
    this.deleted = false,
    this.page = 0,
    this.hasNext = false,
    this.online = false,
    this.accessible = true,
    this.writable = false,
    this.realtimeConnected = false,
    this.synchronizedAt,
    this.save = SaveStatus.idle,
    this.failure,
    this.person,
  });
  final List<PersonSummary> rows;
  final PeopleLoad load;
  final String query;
  final bool deleted, hasNext, online, accessible, writable, realtimeConnected;
  final int page;
  final DateTime? synchronizedAt;
  final SaveStatus save;
  final CloudFailureKind? failure;
  final Person? person;
  bool get canWrite =>
      accessible && online && writable && save != SaveStatus.saving;
}

class PeopleController extends Cubit<PeopleState> {
  PeopleController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const PeopleState());
  final PeopleRepository repository;
  final EventController events;
  final Duration pollInterval;
  static const pageSize = 50;
  StreamSubscription<RepositorySignal>? _signals;
  StreamSubscription<EventState>? _events;
  Timer? _poll, _search;
  Future<void>? _refreshing, _closing;
  bool _started = false, _stopped = false, _again = false;
  bool _denied = false;
  int _generation = 0;
  String? _selected;
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
    List<PersonSummary>? rows,
    PeopleLoad? load,
    String? query,
    bool? deleted,
    int? page,
    bool? hasNext,
    bool? online,
    bool? realtime,
    SaveStatus? save,
    CloudFailureKind? failure,
    Person? person,
    bool clearPerson = false,
    bool clear = false,
    DateTime? at,
  }) {
    if (_stopped) return;
    emit(
      PeopleState(
        rows: clear ? const [] : rows ?? state.rows,
        load: load ?? state.load,
        query: query ?? state.query,
        deleted: deleted ?? state.deleted,
        page: page ?? state.page,
        hasNext: hasNext ?? state.hasNext,
        online: online ?? state.online,
        accessible: _access && !_denied,
        writable: _writable,
        realtimeConnected: realtime ?? state.realtimeConnected,
        synchronizedAt: clear ? null : at ?? state.synchronizedAt,
        save: save ?? state.save,
        failure: failure,
        person: clear || clearPerson ? null : person ?? state.person,
      ),
    );
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _events = events.stream.listen((_) {
      if (!_access) {
        _generation++;
        _selected = null;
        _set(
          clear: true,
          online: false,
          load: PeopleLoad.error,
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

  void search(String query, {bool? deleted}) {
    _generation++;
    _set(
      query: query,
      deleted: deleted,
      page: 0,
      rows: [],
      hasNext: false,
      load: PeopleLoad.loading,
    );
    _search?.cancel();
    _search = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(reconcile()),
    );
  }

  Future<void> page(int value) async {
    if (value < 0) return;
    _generation++;
    _set(page: value, rows: [], load: PeopleLoad.loading);
    await reconcile();
  }

  Future<void> select(String? id) async {
    _selected = id;
    _generation++;
    _set(clearPerson: true);
    if (id != null) await reconcile();
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
      final selected = _selected;
      if (state.load == PeopleLoad.initial) _set(load: PeopleLoad.loading);
      try {
        final rows = await repository.readPage(
          query: state.query,
          deleted: state.deleted,
          limit: pageSize + 1,
          offset: state.page * pageSize,
        );
        final person = selected == null
            ? null
            : await repository.read(selected);
        if (_stopped || generation != _generation || !_access) continue;
        if (rows.any((p) => p.eventId != repository.eventId) ||
            (person != null && person.summary.eventId != repository.eventId)) {
          throw const CloudFailure(CloudFailureKind.unauthorized);
        }
        final unique = {for (final p in rows) p.id: p}.values.toList();
        _denied = false;
        _set(
          rows: List.unmodifiable(unique.take(pageSize)),
          hasNext: unique.length > pageSize,
          online: true,
          at: DateTime.now().toUtc(),
          person: person,
          clearPerson: selected == null,
          load: unique.isEmpty ? PeopleLoad.empty : PeopleLoad.data,
        );
      } on CloudFailure catch (error) {
        if (_stopped || generation != _generation) continue;
        _denied = error.kind == CloudFailureKind.unauthorized;
        _set(
          online: false,
          load: PeopleLoad.error,
          failure: error.kind,
          clear:
              _denied ||
              !EventSnapshot.isTimestampUsable(
                state.synchronizedAt,
                DateTime.now().toUtc(),
              ),
          clearPerson: true,
        );
      } catch (_) {
        if (_stopped || generation != _generation) continue;
        _set(
          online: false,
          load: PeopleLoad.error,
          failure: CloudFailureKind.unknown,
          clearPerson: true,
          clear: !EventSnapshot.isTimestampUsable(
            state.synchronizedAt,
            DateTime.now().toUtc(),
          ),
        );
      }
    } while (_again && !_stopped && _access);
  }

  Future<List<PersonSummary>> duplicates(
    PersonInput input, {
    String? excludeId,
  }) {
    if (_stopped || !state.canWrite) {
      throw const CloudFailure(CloudFailureKind.unavailable);
    }
    return repository.duplicates(input, excludeId: excludeId);
  }

  Future<bool> save(
    PersonInput input, {
    required String requestId,
    Person? base,
  }) => _mutate(() async {
    await repository.save(input, requestId: requestId, base: base);
  });
  Future<bool> setDeleted(PersonSummary base, bool deleted) =>
      _mutate(() => repository.setDeleted(base, deleted));
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
      final kind = error is CloudFailure
          ? error.kind
          : CloudFailureKind.unknown;
      if (kind == CloudFailureKind.unauthorized) _denied = true;
      _set(
        save: kind == CloudFailureKind.conflict
            ? SaveStatus.conflict
            : SaveStatus.failed,
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
    _search?.cancel();
    await _events?.cancel();
    await _signals?.cancel();
    await repository.dispose();
  }
}
