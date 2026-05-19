import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'settings_screen.dart';
import 'task_edit_screen.dart';

enum TaskFilter { upcoming, complete }

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
    }
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: CupertinoSlidingSegmentedControl<TaskFilter>(
                    groupValue: _filter,
                    backgroundColor: AppColors.surfaceVariant,
                    thumbColor: AppColors.surface,
                    onValueChanged: (v) {
                      if (v != null) setState(() => _filter = v);
                    },
                    children: const {
                      TaskFilter.upcoming: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Upcoming'),
                      ),
                      TaskFilter.complete: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Complete'),
                      ),
                    },
                  ),
                ),
                Expanded(
                  child: tasks.when(
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
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [_GroupedTaskList(tasks: list)],
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _BottomCircleButton(
                icon: CupertinoIcons.settings,
                onPressed: _openSettings,
                tooltip: 'Settings',
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _BottomCircleButton(
                icon: CupertinoIcons.add,
                onPressed: _openNewTask,
                tooltip: 'New task',
                filled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCircleButton extends StatelessWidget {
  const _BottomCircleButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? AppColors.primary : AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            size: filled ? 28 : 24,
            color: filled ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: button);
    return button;
  }
}

class _GroupedTaskList extends ConsumerWidget {
  const _GroupedTaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < tasks.length; i++) ...[
              _SwipeRow(
                task: tasks[i],
                onToggleDone: () =>
                    ref.read(tasksProvider.notifier).toggleDone(tasks[i]),
                onDelete: () =>
                    ref.read(tasksProvider.notifier).remove(tasks[i].id!),
                child: TaskTile(
                  task: tasks[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskEditScreen(task: tasks[i]),
                    ),
                  ),
                  onToggleDone: (_) =>
                      ref.read(tasksProvider.notifier).toggleDone(tasks[i]),
                ),
              ),
              if (i != tasks.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 52),
                  child: Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwipeRow extends StatelessWidget {
  const _SwipeRow({
    required this.task,
    required this.child,
    required this.onToggleDone,
    required this.onDelete,
  });

  final Task task;
  final Widget child;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(CupertinoIcons.check_mark_circled_solid,
                color: Colors.white),
            const SizedBox(width: 8),
            Text(
              task.isDone ? 'Mark undone' : 'Complete',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.destructive,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(CupertinoIcons.delete_solid, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggleDone();
          return false; // keep the row visible, just toggled
        }
        return _confirmDelete(context, task.title);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) onDelete();
      },
      child: child,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete task?'),
        content: Text('"$title" will be permanently removed.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        children: const [
          Icon(CupertinoIcons.checkmark_seal,
              size: 56, color: AppColors.onSurfaceFaint),
          SizedBox(height: 12),
          Text('No tasks',
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              )),
          SizedBox(height: 4),
          Text(
            'Tap + to add a new one.',
            style: AppTextStyles.footnote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
