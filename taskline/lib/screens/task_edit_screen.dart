import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/providers.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  static final _dateFormat = DateFormat('EEE, MMM d, y');
  static final _timeFormat = DateFormat('h:mm a');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _deadline;
  late Recurrence _recurrence;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.task;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _deadline = existing?.deadline.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    _recurrence = existing?.recurrence ?? Recurrence.none;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked == null) return;
    setState(() {
      _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _deadline.hour,
        _deadline.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (picked == null) return;
    setState(() {
      _deadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(tasksProvider.notifier);
    final description = _descriptionController.text.trim();

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        deadline: _deadline,
        recurrence: _recurrence,
      );
      await notifier.edit(updated);
    } else {
      await notifier.add(Task(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        deadline: _deadline,
        recurrence: _recurrence,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Pay electric bill',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Deadline', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dateFormat.format(_deadline)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_timeFormat.format(_deadline)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<Recurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: Recurrence.none, child: Text('Does not repeat')),
                DropdownMenuItem(value: Recurrence.daily, child: Text('Daily')),
                DropdownMenuItem(
                    value: Recurrence.weekly, child: Text('Weekly')),
                DropdownMenuItem(
                    value: Recurrence.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _recurrence = v ?? Recurrence.none),
            ),
          ],
        ),
      ),
    );
  }
}
