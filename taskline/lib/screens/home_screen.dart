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

  /// Upcoming view: dated tasks first, then a "NO DEADLINE" section holding
  /// deadline-less todos. [list] is already ordered (dated by deadline, todos
  /// after) by the provider.
  Widget _buildUpcoming(List<Task> list) {
    final dated = list.where((t) => t.deadline != null).toList();
    final todos = list.where((t) => t.deadline == null).toList();

    final children = <Widget>[];
    for (var i = 0; i < dated.length; i++) {
      children.add(TaskTile(
        task: dated[i],
        onTap: () => _openTaskEditor(dated[i]),
      ));
      if (i != dated.length - 1) children.add(const SizedBox(height: 14));
    }
    if (todos.isNotEmpty) {
      if (dated.isNotEmpty) children.add(const SizedBox(height: 24));
      children.add(Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text('NO DEADLINE', style: AppTextStyles.sectionHeader),
      ));
      for (var i = 0; i < todos.length; i++) {
        children.add(TaskTile(
          task: todos[i],
          onTap: () => _openTaskEditor(todos[i]),
        ));
        if (i != todos.length - 1) children.add(const SizedBox(height: 14));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: children,
    );
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
                      Flexible(
                        child: Text(
                          'Taskline',
                          style: AppTextStyles.largeTitle
                              .copyWith(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _BlinkingCursor(),
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
                            // Key on the accent colour so a palette/brightness
                            // change gives the widget a new identity and forces
                            // a rebuild (a keyless const instance would be
                            // reused and keep stale colours).
                            if (list.isEmpty) {
                              return _EmptyState(
                                  key: ValueKey(AppColors.primary));
                            }
                            if (_filter == TaskFilter.upcoming) {
                              return _buildUpcoming(list);
                            }
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
      return 'TASKS';
    case TaskFilter.complete:
      return 'COMPLETE';
    case TaskFilter.calendar:
      return 'CALENDAR';
  }
}

/// A solid block that blinks like a terminal text cursor, parked after the
/// "> TASKLINE" prompt in the header.
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 4),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Opacity(
          opacity: _controller.value < 0.5 ? 1 : 0,
          child: Container(
            width: 12,
            height: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal,
              size: 72, color: AppColors.onSurfaceFaint),
          const SizedBox(height: 16),
          Text('NO TASKS', style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text('// tap + to add one',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.onSurfaceMuted,
              )),
        ],
      ),
    );
  }
}
