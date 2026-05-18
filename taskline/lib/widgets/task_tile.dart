import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleDone,
  });

  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleDone;

  static final _dateFormat = DateFormat('EEE, MMM d • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localDeadline = task.deadline.toLocal();
    final isOverdue = !task.isDone && localDeadline.isBefore(DateTime.now());

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      decoration: task.isDone ? TextDecoration.lineThrough : null,
      color: task.isDone ? theme.disabledColor : null,
    );

    final deadlineStyle = theme.textTheme.bodySmall?.copyWith(
      color: isOverdue ? theme.colorScheme.error : theme.hintColor,
      fontWeight: isOverdue ? FontWeight.w600 : null,
    );

    return ListTile(
      onTap: onTap,
      leading: Checkbox(value: task.isDone, onChanged: onToggleDone),
      title: Text(task.title, style: titleStyle),
      subtitle: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.event,
            size: 14,
            color: deadlineStyle?.color,
          ),
          const SizedBox(width: 4),
          Text(_dateFormat.format(localDeadline), style: deadlineStyle),
          if (task.recurrence != Recurrence.none) ...[
            const SizedBox(width: 8),
            Icon(Icons.repeat, size: 14, color: theme.hintColor),
            const SizedBox(width: 2),
            Text(task.recurrence.name, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
