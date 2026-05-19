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
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              _Checkbox(value: task.isDone, onChanged: onToggleDone),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Due: $formatted',
                          style: const TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (task.recurrence != Recurrence.none) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.repeat,
                              size: 12, color: AppColors.onSurfaceMuted),
                          const SizedBox(width: 2),
                          Text(
                            task.recurrence.name,
                            style: const TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _TrailingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppColors.onSurface : AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value
                ? AppColors.onSurface
                : AppColors.onSurfaceMuted.withValues(alpha: 0.5),
          ),
        ),
        child: value
            ? const Icon(Icons.check, size: 18, color: AppColors.background)
            : null,
      ),
    );
  }
}

class _TrailingIndicator extends StatelessWidget {
  const _TrailingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 18,
        color: AppColors.onSurface,
      ),
    );
  }
}
