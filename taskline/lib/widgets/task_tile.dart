import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'nb.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
  });

  final Task task;
  final VoidCallback? onTap;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('DELETE TASK?', style: AppTextStyles.title),
        content: Text(
          '"${task.title}" will be permanently removed.',
          style: AppTextStyles.body,
        ),
        actions: [
          NbButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            color: AppColors.surface,
            child: const Text('Cancel'),
          ),
          NbButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            color: AppColors.destructive,
            foregroundColor: AppColors.onSurface,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && task.id != null) {
      await ref.read(tasksProvider.notifier).remove(task.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDeadline = task.deadline.toLocal();
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final formatted =
        DateFormat(settings.combinedPattern).format(localDeadline);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: NbCard(
        color: task.isDone ? AppColors.surfaceVariant : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            NbCheckbox(
              value: task.isDone,
              onChanged: (_) =>
                  ref.read(tasksProvider.notifier).toggleDone(task),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 17,
                      color: task.isDone
                          ? AppColors.onSurfaceFaint
                          : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatted.toUpperCase(),
                        style: AppTextStyles.footnote.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (task.recurrence != Recurrence.none) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.repeat,
                            size: 12, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 2),
                        Text(
                          task.recurrence.name.toUpperCase(),
                          style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            NbIconButton(
              icon: Icons.close,
              color: AppColors.destructive,
              size: 28,
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
