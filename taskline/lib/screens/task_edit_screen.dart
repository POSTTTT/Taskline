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
            borderRadius: BorderRadius.circular(24),
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
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Time',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
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
                        child: CupertinoTheme(
                          data: const CupertinoThemeData(
                            brightness: Brightness.dark,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 22,
                              ),
                            ),
                          ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: _isEditing ? 'Edit task' : 'New tasks'),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      const _FieldLabel('Task name'),
                      TextFormField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.onSurface),
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        minLines: 5,
                        style: const TextStyle(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Due date',
                              child: _PillSelector(
                                text: dateFormat.format(_deadline),
                                onTap: _pickDate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _LabeledField(
                              label: 'Time',
                              child: _PillSelector(
                                text: timeFormat.format(_deadline),
                                onTap: _pickTime,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Repeat'),
                      _RecurrenceDropdown(
                        value: _recurrence,
                        onChanged: (v) => setState(() => _recurrence = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BottomButton(
                        label: 'Save',
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _BottomButton(
                        label: 'Cancel',
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        child,
      ],
    );
  }
}

class _PillSelector extends StatelessWidget {
  const _PillSelector({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurrenceDropdown extends StatelessWidget {
  const _RecurrenceDropdown({required this.value, required this.onChanged});

  final Recurrence value;
  final ValueChanged<Recurrence> onChanged;

  String _label(Recurrence r) {
    switch (r) {
      case Recurrence.none:
        return 'Does not repeat';
      case Recurrence.daily:
        return 'Daily';
      case Recurrence.weekly:
        return 'Weekly';
      case Recurrence.monthly:
        return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Recurrence>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant,
          iconEnabledColor: AppColors.onSurface,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 16,
          ),
          items: Recurrence.values
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(_label(r)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
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

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
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
