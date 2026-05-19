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
    final settings = await ref.watch(settingsProvider.future);
    final tasks = await repo.getAll();
    await ref.read(notificationServiceProvider).syncAll(tasks, settings);
    return tasks;
  }

  Future<AppSettings> _settings() => ref.read(settingsProvider.future);

  Future<void> _refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(taskRepositoryProvider.future);
      return repo.getAll();
    });
  }

  Future<void> add(Task task) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    final saved = await repo.create(task);
    final settings = await _settings();
    await ref.read(notificationServiceProvider).schedule(saved, settings);
    await _refresh();
  }

  Future<void> edit(Task task) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await repo.update(task);
    final notifications = ref.read(notificationServiceProvider);
    final settings = await _settings();
    await notifications.cancel(task.id!);
    await notifications.schedule(task, settings);
    await _refresh();
  }

  Future<void> remove(int id) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    await ref.read(notificationServiceProvider).cancel(id);
    await repo.delete(id);
    await _refresh();
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
