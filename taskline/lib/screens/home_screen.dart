import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/providers.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskline'),
        centerTitle: false,
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : _TaskList(tasks: items),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }

  void _openEditor(BuildContext context, {Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
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
      separatorBuilder: (_, _) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('No tasks yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tap "New task" to add your first deadline.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
