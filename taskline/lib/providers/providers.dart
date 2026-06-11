import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../services/database.dart';
import '../services/notification_service.dart';
import '../services/task_repository.dart';
import 'settings_provider.dart';

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return TaskRepository(db.database);
});

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repo = await ref.watch(taskRepositoryProvider.future);
    // Watch only the reminder cadence fields: cosmetic settings (theme,
    // palette, date format, notes) must not re-read the DB or cancel and
    // reschedule every OS notification.
    await ref.watch(settingsProvider.selectAsync(
      (s) => (
        s.dueIn1Hour,
        s.dueIn1Day,
        s.dueIn1Week,
        s.dueIn1Month,
        s.dueIn1Year,
        s.moreThan1Year,
      ),
    ));
    final settings = await ref.read(settingsProvider.future);
    final tasks = await repo.getAll();
    await ref.read(notificationServiceProvider).syncAll(tasks, settings);
    return tasks;
  }

  Future<AppSettings> _settings() => ref.read(settingsProvider.future);

  List<Task> get _current => state.value ?? const [];

  /// Pushes a new task list into state immediately, kept in the same order as
  /// `repo.getAll()`: dated tasks first by soonest deadline, then deadline-less
  /// todos (newest first). This drives optimistic UI updates so a mutation
  /// never flashes the list to a loading spinner or waits on a full DB re-read.
  void _setTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      final da = a.deadline;
      final db = b.deadline;
      if (da == null && db == null) return b.createdAt.compareTo(a.createdAt);
      if (da == null) return 1; // todos sort after dated tasks
      if (db == null) return -1;
      return da.compareTo(db);
    });
    state = AsyncValue.data(tasks);
  }

  /// Full reload from the DB. Only used as an error-recovery fallback now —
  /// the happy path updates state in place.
  Future<void> _reloadFromDb() async {
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(taskRepositoryProvider.future);
      return repo.getAll();
    });
  }

  Future<void> add(Task task) async {
    try {
      final repo = await ref.read(taskRepositoryProvider.future);
      final saved = await repo.create(task);
      _setTasks([..._current, saved]);
      final settings = await _settings();
      await ref.read(notificationServiceProvider).schedule(saved, settings);
    } catch (_) {
      await _reloadFromDb();
    }
  }

  Future<void> edit(Task task) async {
    // Update the UI first, then persist + reschedule notifications. The user
    // sees the change instantly instead of waiting on ~100 native notification
    // calls and a database round-trip.
    _setTasks([for (final t in _current) t.id == task.id ? task : t]);
    try {
      final repo = await ref.read(taskRepositoryProvider.future);
      await repo.update(task);
      final notifications = ref.read(notificationServiceProvider);
      final settings = await _settings();
      await notifications.cancel(task.id!);
      await notifications.schedule(task, settings);
    } catch (_) {
      await _reloadFromDb();
    }
  }

  Future<void> remove(int id) async {
    _setTasks(_current.where((t) => t.id != id).toList());
    try {
      final repo = await ref.read(taskRepositoryProvider.future);
      await ref.read(notificationServiceProvider).cancel(id);
      await repo.delete(id);
    } catch (_) {
      await _reloadFromDb();
    }
  }

  Future<void> toggleDone(Task task) async {
    await edit(task.copyWith(isDone: !task.isDone));
  }

  Future<void> resyncNotifications() async {
    final current = state.value;
    if (current == null) return;
    final settings = await _settings();
    await ref.read(notificationServiceProvider).syncAll(current, settings);
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);
