import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleDone,
  });

  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDeadline = task.deadline.toLocal();
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final formatted = DateFormat(settings.combinedPattern).format(localDeadline);

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _RadioCheck(value: task.isDone, onChanged: onToggleDone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.body.copyWith(
                        color: task.isDone
                            ? AppColors.onSurfaceMuted
                            : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(formatted, style: AppTextStyles.footnote),
                        if (task.recurrence != Recurrence.none) ...[
                          const SizedBox(width: 8),
                          const Icon(CupertinoIcons.repeat,
                              size: 12, color: AppColors.onSurfaceMuted),
                          const SizedBox(width: 2),
                          Text(task.recurrence.name,
                              style: AppTextStyles.footnote),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right,
                  size: 16, color: AppColors.onSurfaceFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCheck extends StatelessWidget {
  const _RadioCheck({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? AppColors.primary : AppColors.onSurfaceFaint,
            width: 1.5,
          ),
        ),
        child: value
            ? const Icon(CupertinoIcons.check_mark,
                size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
