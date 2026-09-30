import 'dart:async';
import 'package:bloc/bloc.dart';
import '../domain/entities/task.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/tasks_repository.dart';
import 'event_controller.dart';

enum TaskFilter { all, open, overdue }

class TasksState {
  const TasksState({
    this.tasks = const [],
    this.assignees = const [],
    this.selected,
    this.query = '',
    this.deleted = false,
    this.loading = true,
    this.online = false,
    this.writable = false,
    this.realtimeConnected = false,
    this.save = SaveStatus.idle,
    this.failure,
  });
  final List<EventTask> tasks;
  final List<TaskAssignee> assignees;
  final EventTask? selected;
  final String query;
  final bool deleted, loading, online, writable, realtimeConnected;
  final SaveStatus save;
  final CloudFailureKind? failure;
  List<EventTask> visible(TaskFilter filter, DateTime now) => tasks
      .where(
        (task) => switch (filter) {
          TaskFilter.all => true,
          TaskFilter.open => !(task.status?.terminal ?? false),
          TaskFilter.overdue => task.isOverdue(now),
        },
      )
      .toList();
  bool get canWrite => online && writable && save != SaveStatus.saving;
  TasksState copy({
    List<EventTask>? tasks,
    List<TaskAssignee>? assignees,
    EventTask? selected,
    bool clearSelected = false,
    String? query,
    bool? deleted,
    bool? loading,
    bool? online,
    bool? writable,
    bool? realtimeConnected,
    SaveStatus? save,
    CloudFailureKind? failure,
    bool clearFailure = false,
  }) => TasksState(
    tasks: tasks ?? this.tasks,
    assignees: assignees ?? this.assignees,
    selected: clearSelected ? null : selected ?? this.selected,
    query: query ?? this.query,
    deleted: deleted ?? this.deleted,
    loading: loading ?? this.loading,
    online: online ?? this.online,
    writable: writable ?? this.writable,
    realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    save: save ?? this.save,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class TasksController extends Cubit<TasksState> {
  TasksController(
    this.repository,
    this.events, {
    this.pollInterval = const Duration(seconds: 20),
  }) : super(const TasksState());
  final TasksRepository repository;
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
  void _emit(TasksState value) {
    if (!_stopped) emit(value);
  }

  void _clear() {
    _generation++;
    _selectedId = null;
    _emit(TasksState(loading: false, failure: CloudFailureKind.unauthorized));
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
    _emit(state.copy(query: value, tasks: [], loading: true));
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

  void select(EventTask? trip) {
    _generation++;
    _selectedId = trip?.id;
    _emit(state.copy(selected: trip, clearSelected: trip == null));
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
        final tasks = await repository.listTasks(
          query: state.query,
          deleted: state.deleted,
        );
        final assignees = await repository.assignees();
        final selected = selectedId == null
            ? null
            : await repository.readTask(selectedId);
        if (_stopped || generation != _generation || !_access) continue;
        _emit(
          state.copy(
            tasks: List.unmodifiable(tasks),
            assignees: List.unmodifiable(assignees),
            selected: selected,
            clearSelected: selected == null,
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

  Future<bool> saveTask(
    TaskInput input, {
    required String requestId,
    EventTask? base,
  }) => _mutate(() async {
    await repository.saveTask(input, requestId: requestId, base: base);
  });
  Future<bool> transition(EventTask base, TaskStatus status) =>
      _mutate(() => repository.transition(base, status));
  Future<bool> setDeleted(EventTask base, bool deleted) =>
      _mutate(() => repository.setDeleted(base, deleted));
  Future<bool> _mutate(Future<void> Function() action) async {
    if (_stopped ||
        !_access ||
        !events.state.capabilities(repository.eventId).canEdit ||
        !state.canWrite) {
      return false;
    }
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
      if (_stopped || !_access) return false;
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
