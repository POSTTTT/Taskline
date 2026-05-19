import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
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
    _deadline = existing?.deadline.toLocal() ?? DateTime.now();
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
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final use24h = settings.timeFormat == TimeFormatPref.hour24;

    var temp = _deadline;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Time',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.of(ctx).pop(temp),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 220,
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          GestureBinding.instance.pointerSignalResolver
                              .register(event, (_) {});
                        }
                      },
                      child: ScrollConfiguration(
                        behavior: const _DragWithMouseScrollBehavior(),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: use24h,
                          initialDateTime: _deadline,
                          minuteInterval: 1,
                          onDateTimeChanged: (v) => temp = DateTime(
                            _deadline.year,
                            _deadline.month,
                            _deadline.day,
                            v.hour,
                            v.minute,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickRecurrence() async {
    final picked = await showCupertinoModalPopup<Recurrence>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Repeat'),
        actions: [
          for (final r in Recurrence.values)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(r),
              isDefaultAction: r == _recurrence,
              child: Text(_recurrenceLabel(r)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (picked != null) setState(() => _recurrence = picked);
  }

  String _recurrenceLabel(Recurrence r) {
    switch (r) {
      case Recurrence.none:
        return 'Never';
      case Recurrence.daily:
        return 'Daily';
      case Recurrence.weekly:
        return 'Weekly';
      case Recurrence.monthly:
        return 'Monthly';
    }
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
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final dateFormat = DateFormat(settings.dateFormat.pattern);
    final timeFormat = DateFormat(settings.timeFormat.pattern);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 80,
        leading: CupertinoButton(
          padding: const EdgeInsets.only(left: 16),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.primary, fontSize: 17),
          ),
        ),
        title: Text(_isEditing ? 'Edit Task' : 'New Task',
            style: AppTextStyles.title),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 16),
            onPressed: _saving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _GroupedSection(
              children: [
                _CellTextField(
                  controller: _titleController,
                  hint: 'Title',
                  autofocus: !_isEditing,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const _CellDivider(),
                _CellTextField(
                  controller: _descriptionController,
                  hint: 'Notes',
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Deadline'),
            _GroupedSection(
              children: [
                _ValueCell(
                  label: 'Date',
                  value: dateFormat.format(_deadline),
                  onTap: _pickDate,
                ),
                const _CellDivider(),
                _ValueCell(
                  label: 'Time',
                  value: timeFormat.format(_deadline),
                  onTap: _pickTime,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Repeat'),
            _GroupedSection(
              children: [
                _ValueCell(
                  label: 'Frequency',
                  value: _recurrenceLabel(_recurrence),
                  onTap: _pickRecurrence,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        color: AppColors.surface,
        child: Column(children: children),
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 16),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: AppColors.divider,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text(label.toUpperCase(), style: AppTextStyles.sectionHeader),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(label, style: AppTextStyles.body),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.onSurfaceFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellTextField extends StatelessWidget {
  const _CellTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool autofocus;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: AppTextStyles.body,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceFaint),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _DragWithMouseScrollBehavior extends MaterialScrollBehavior {
  const _DragWithMouseScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}
