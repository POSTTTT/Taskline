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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              _FilterTabs(
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, thickness: 0.5),
              const SizedBox(height: 12),
              Expanded(
                child: tasks.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error: $err',
                        style:
                            const TextStyle(color: AppColors.onSurfaceMuted)),
                  ),
                  data: (all) {
                    final list = _filtered(all);
                    if (list.isEmpty) return const _EmptyState();
                    return _TaskList(tasks: list);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.settings,
                    onTap: _openSettings,
                    tooltip: 'Settings',
                  ),
                  _CircleButton(
                    icon: Icons.add,
                    onTap: _openNewTask,
                    tooltip: 'New task',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final TaskFilter value;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabPill(
            label: 'Upcoming',
            selected: value == TaskFilter.upcoming,
            onTap: () => onChanged(TaskFilter.upcoming),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TabPill(
            label: 'Complete',
            selected: value == TaskFilter.complete,
            onTap: () => onChanged(TaskFilter.complete),
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, task.title),
          onDismissed: (_) =>
              ref.read(tasksProvider.notifier).remove(task.id!),
          child: TaskTile(
            task: task,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
            ),
            onToggleDone: (_) =>
                ref.read(tasksProvider.notifier).toggleDone(task),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"$title" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline,
              size: 64, color: AppColors.onSurfaceMuted),
          SizedBox(height: 12),
          Text('Nothing here',
              style: TextStyle(
                  color: AppColors.onSurfaceMuted, fontSize: 16)),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.circularButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon,
              size: 24, color: AppColors.circularButtonIcon),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: button);
    return button;
  }
}
