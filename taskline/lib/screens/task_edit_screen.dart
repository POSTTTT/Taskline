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
import '../widgets/nb.dart';

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
  DateTime? _recurrenceEndDate;
  // When false this is a deadline-less "todo": no due date, and [_recurrence]
  // acts as an optional "remind me" nudge cadence instead of a repeat rule.
  late bool _hasDeadline;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.task;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _deadline = existing?.deadline?.toLocal() ?? DateTime.now();
    _recurrence = existing?.recurrence ?? Recurrence.none;
    _recurrenceEndDate = existing?.recurrenceEndDate?.toLocal();
    // New tasks default to scheduled; an existing todo (null deadline) opens
    // in todo mode.
    _hasDeadline = existing == null ? true : existing.deadline != null;
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _deadline,
      firstDate: _deadline,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) => _brutalistPickerTheme(context, child),
    );
    if (picked == null) return;
    setState(() => _recurrenceEndDate =
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }

  void _clearRecurrenceEndDate() {
    setState(() => _recurrenceEndDate = null);
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
      builder: (context, child) => _brutalistPickerTheme(context, child),
    );
    if (picked == null) return;
    setState(() {
      _deadline = DateTime(picked.year, picked.month, picked.day,
          _deadline.hour, _deadline.minute);
    });
  }

  /// Re-skins the stock Material date picker so it matches the terminal
  /// theme — green selection chip, near-black text, bold weights, sharp corners.
  Widget _brutalistPickerTheme(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    final dark = appBrightness.value == Brightness.dark;
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme(
          brightness: dark ? Brightness.dark : Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          secondary: AppColors.primary,
          onSecondary: AppColors.onPrimary,
          error: AppColors.destructive,
          onError: AppColors.onSurface,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
                color: AppColors.border, width: NbStyles.borderWidth),
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          headerBackgroundColor: AppColors.primary,
          headerForegroundColor: AppColors.onPrimary,
          headerHeadlineStyle: AppTextStyles.title,
          headerHelpStyle: AppTextStyles.sectionHeader,
          weekdayStyle: AppTextStyles.footnote
              .copyWith(fontWeight: FontWeight.w700),
          dayStyle: AppTextStyles.body,
          dayForegroundColor: WidgetStatePropertyAll(AppColors.onSurface),
          dayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          todayForegroundColor: WidgetStatePropertyAll(AppColors.onSurface),
          todayBorder: BorderSide(
              color: AppColors.border, width: NbStyles.borderWidth),
          yearStyle: AppTextStyles.body,
          shape: RoundedRectangleBorder(
            side: BorderSide(
                color: AppColors.border, width: NbStyles.borderWidth),
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
          dayShape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
            ),
          ),
          dividerColor: AppColors.border,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            textStyle: AppTextStyles.button,
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Future<void> _pickTime() async {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final use24h = settings.timeFormat == TimeFormatPref.hour24;
    var temp = _deadline;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        final dark = appBrightness.value == Brightness.dark;
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
                color: AppColors.border, width: NbStyles.borderWidth),
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PICK TIME', style: AppTextStyles.title),
                  const SizedBox(height: 8),
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
                          data: CupertinoThemeData(
                            brightness:
                                dark ? Brightness.dark : Brightness.light,
                            primaryColor: AppColors.onSurface,
                            scaffoldBackgroundColor: AppColors.surface,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: use24h,
                            initialDateTime: _deadline,
                            minuteInterval: 1,
                            itemExtent: 38,
                            backgroundColor: AppColors.surface,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: NbButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          color: AppColors.surface,
                          expand: true,
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NbButton(
                          onPressed: () => Navigator.of(ctx).pop(temp),
                          color: AppColors.primary,
                          expand: true,
                          child: const Text('DONE'),
                        ),
                      ),
                    ],
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

  Future<void> _pickRecurrence({String title = 'REPEAT'}) async {
    final picked = await showDialog<Recurrence>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 12),
                for (final r in Recurrence.values) ...[
                  NbButton(
                    onPressed: () => Navigator.of(ctx).pop(r),
                    color: r == _recurrence
                        ? AppColors.primary
                        : AppColors.surface,
                    expand: true,
                    child: Text(_recurrenceLabel(r).toUpperCase()),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
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
    final title = _titleController.text.trim();

    // Scheduled: keep the deadline + repeat rule. Todo: no deadline, and
    // [_recurrence] is the "remind me" nudge cadence (no repeat-until).
    final DateTime? deadline = _hasDeadline ? _deadline : null;
    final DateTime? effectiveEnd =
        (_hasDeadline && _recurrence != Recurrence.none)
            ? _recurrenceEndDate
            : null;

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        deadline: deadline,
        recurrence: _recurrence,
        recurrenceEndDate: effectiveEnd,
      );
      await notifier.edit(updated);
    } else {
      await notifier.add(Task(
        title: title,
        description: description.isEmpty ? null : description,
        deadline: deadline,
        recurrence: _recurrence,
        recurrenceEndDate: effectiveEnd,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NbIconButton(
                      icon: Icons.arrow_back,
                      size: 36,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing ? 'EDIT TASK' : 'NEW TASK',
                        style: AppTextStyles.title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: NbStyles.borderWidth,
                  color: AppColors.border,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _Label('TASK NAME'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.body,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                        decoration: const InputDecoration(hintText: 'e.g. Pay bill'),
                      ),
                      const SizedBox(height: 16),
                      _Label('DESCRIPTION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        minLines: 4,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                            hintText: 'Optional notes'),
                      ),
                      const SizedBox(height: 16),
                      _Label('TYPE'),
                      const SizedBox(height: 6),
                      NbSegmentedControl<bool>(
                        value: _hasDeadline,
                        options: const [true, false],
                        labelOf: (v) => v ? 'SCHEDULED' : 'TODO',
                        onChanged: (v) => setState(() => _hasDeadline = v),
                      ),
                      const SizedBox(height: 16),
                      if (_hasDeadline) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _Label('DUE DATE'),
                                  const SizedBox(height: 6),
                                  NbButton(
                                    onPressed: _pickDate,
                                    color: AppColors.surface,
                                    expand: true,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Text(
                                        dateFormat.format(_deadline)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _Label('TIME'),
                                  const SizedBox(height: 6),
                                  NbButton(
                                    onPressed: _pickTime,
                                    color: AppColors.surface,
                                    expand: true,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Text(
                                        timeFormat.format(_deadline)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Label('REPEAT'),
                        const SizedBox(height: 6),
                        NbButton(
                          onPressed: _pickRecurrence,
                          color: AppColors.surface,
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                              _recurrenceLabel(_recurrence).toUpperCase()),
                        ),
                        if (_recurrence != Recurrence.none) ...[
                          const SizedBox(height: 16),
                          _Label('REPEAT UNTIL'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: NbButton(
                                  onPressed: _pickRecurrenceEndDate,
                                  color: AppColors.surface,
                                  expand: true,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  child: Text(
                                    _recurrenceEndDate == null
                                        ? 'NO END DATE'
                                        : dateFormat
                                            .format(_recurrenceEndDate!)
                                            .toUpperCase(),
                                  ),
                                ),
                              ),
                              if (_recurrenceEndDate != null) ...[
                                const SizedBox(width: 12),
                                NbIconButton(
                                  icon: Icons.close,
                                  size: 48,
                                  color: AppColors.surface,
                                  onPressed: _clearRecurrenceEndDate,
                                  tooltip: 'Clear end date',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ] else ...[
                        _Label('REMIND ME'),
                        const SizedBox(height: 6),
                        NbButton(
                          onPressed: () =>
                              _pickRecurrence(title: 'REMIND ME'),
                          color: AppColors.surface,
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                              _recurrenceLabel(_recurrence).toUpperCase()),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _recurrence == Recurrence.none
                              ? '// no deadline — sits on your todo list with no reminders'
                              : '// no deadline — nudges you ${_recurrenceLabel(_recurrence).toLowerCase()} until done',
                          style: AppTextStyles.footnote,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NbButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        color: AppColors.surface,
                        expand: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NbButton(
                        onPressed: _saving ? null : _save,
                        color: AppColors.primary,
                        expand: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text('SAVE'),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: AppTextStyles.sectionHeader),
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
