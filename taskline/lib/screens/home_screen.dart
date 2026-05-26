import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_view.dart';
import '../widgets/nb.dart';
import '../widgets/task_tile.dart';
import 'settings_screen.dart';
import 'task_edit_screen.dart';

enum TaskFilter { upcoming, complete, calendar }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  TaskFilter _filter = TaskFilter.upcoming;

  List<Task> _filtered(List<Task> all) {
    switch (_filter) {
      case TaskFilter.upcoming:
        return all.where((t) => !t.isDone).toList();
      case TaskFilter.complete:
        return all.where((t) => t.isDone).toList();
      case TaskFilter.calendar:
        return all; // calendar handles its own filtering
    }
  }

  void _openTaskEditor(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
  }

  void _openNewTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text('TASKLINE', style: AppTextStyles.largeTitle),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: NbSegmentedControl<TaskFilter>(
                    value: _filter,
                    options: TaskFilter.values,
                    labelOf: _filterLabel,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                Container(
                  height: NbStyles.borderWidth,
                  color: AppColors.border,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _filter == TaskFilter.calendar
                      ? CalendarView(onTaskTap: _openTaskEditor)
                      : tasks.when(
                          loading: () =>
                              const Center(child: CupertinoActivityIndicator()),
                          error: (err, _) => Center(
                            child: Text('Error: $err',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.destructive)),
                          ),
                          data: (all) {
                            final list = _filtered(all);
                            if (list.isEmpty) return const _EmptyState();
                            return ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 110),
                              itemCount: list.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, i) {
                                final task = list[i];
                                return TaskTile(
                                  task: task,
                                  onTap: () => _openTaskEditor(task),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: NbIconButton(
                icon: Icons.settings,
                color: AppColors.surface,
                size: 48,
                onPressed: _openSettings,
                tooltip: 'Settings',
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: NbIconButton(
                icon: Icons.add,
                color: AppColors.primary,
                size: 56,
                onPressed: _openNewTask,
                tooltip: 'New task',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(TaskFilter f) {
  switch (f) {
    case TaskFilter.upcoming:
      return 'UPCOMING';
    case TaskFilter.complete:
      return 'COMPLETE';
    case TaskFilter.calendar:
      return 'CALENDAR';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 72, color: AppColors.onSurfaceFaint),
          const SizedBox(height: 16),
          Text('NO TASKS', style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text('Tap + to add one.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.onSurfaceMuted,
              )),
        ],
      ),
    );
  }
}
