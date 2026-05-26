import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/nb.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _save(AppSettings next) async {
    await ref.read(settingsProvider.notifier).save(next);
    await ref.read(tasksProvider.notifier).resyncNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NbIconButton(
                    icon: Icons.arrow_back,
                    size: 36,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Text('SETTINGS', style: AppTextStyles.title),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _SectionHeader('NOTIFICATIONS'),
                    NbCard(
                      child: Column(
                        children: [
                          _IntervalRow(
                            label: 'More than 1 year',
                            value: settings.moreThan1Year,
                            onSelect: (v) =>
                                _save(settings.copyWith(moreThan1Year: v)),
                          ),
                          const _CellDivider(),
                          _IntervalRow(
                            label: 'Due in 1 year',
                            value: settings.dueIn1Year,
                            onSelect: (v) =>
                                _save(settings.copyWith(dueIn1Year: v)),
                          ),
                          const _CellDivider(),
                          _IntervalRow(
                            label: 'Due in 1 month',
                            value: settings.dueIn1Month,
                            onSelect: (v) =>
                                _save(settings.copyWith(dueIn1Month: v)),
                          ),
                          const _CellDivider(),
                          _IntervalRow(
                            label: 'Due in 1 week',
                            value: settings.dueIn1Week,
                            onSelect: (v) =>
                                _save(settings.copyWith(dueIn1Week: v)),
                          ),
                          const _CellDivider(),
                          _IntervalRow(
                            label: 'Due in 1 day',
                            value: settings.dueIn1Day,
                            onSelect: (v) =>
                                _save(settings.copyWith(dueIn1Day: v)),
                          ),
                          const _CellDivider(),
                          _IntervalRow(
                            label: 'Due in 1 hour',
                            value: settings.dueIn1Hour,
                            onSelect: (v) =>
                                _save(settings.copyWith(dueIn1Hour: v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader('DISPLAY'),
                    NbCard(
                      child: Column(
                        children: [
                          NbValueRow(
                            label: 'Time format',
                            value: settings.timeFormat.label,
                            onTap: () => _chooseTimeFormat(settings),
                          ),
                          const _CellDivider(),
                          NbValueRow(
                            label: 'Date format',
                            value: settings.dateFormat.label,
                            onTap: () => _chooseDateFormat(settings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader('GENERAL'),
                    NbCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Launch at startup',
                                  style: AppTextStyles.body),
                            ),
                            NbSwitch(
                              value: settings.launchAtStartup,
                              onChanged: (v) => _save(
                                  settings.copyWith(launchAtStartup: v)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader('APPEARANCE'),
                    NbCard(
                      child: NbValueRow(
                        label: 'Theme',
                        value: 'Neo-brutalist',
                        enabled: false,
                        onTap: null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'More themes coming soon.',
                        style: AppTextStyles.footnote,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseTimeFormat(AppSettings settings) async {
    final picked = await _showChoiceDialog<TimeFormatPref>(
      title: 'TIME FORMAT',
      options: TimeFormatPref.values,
      labelOf: (v) => v.label,
      current: settings.timeFormat,
    );
    if (picked != null && picked != settings.timeFormat) {
      await _save(settings.copyWith(timeFormat: picked));
    }
  }

  Future<void> _chooseDateFormat(AppSettings settings) async {
    final picked = await _showChoiceDialog<DateFormatPref>(
      title: 'DATE FORMAT',
      options: DateFormatPref.values,
      labelOf: (v) => v.label,
      current: settings.dateFormat,
    );
    if (picked != null && picked != settings.dateFormat) {
      await _save(settings.copyWith(dateFormat: picked));
    }
  }

  Future<T?> _showChoiceDialog<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T current,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
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
                for (final o in options) ...[
                  NbButton(
                    onPressed: () => Navigator.of(ctx).pop(o),
                    color: o == current
                        ? AppColors.primary
                        : AppColors.surface,
                    expand: true,
                    child: Text(labelOf(o).toUpperCase()),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(label, style: AppTextStyles.sectionHeader),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NbStyles.borderWidth,
      color: AppColors.border,
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.label,
    required this.value,
    required this.onSelect,
  });

  final String label;
  final ReminderInterval value;
  final ValueChanged<ReminderInterval> onSelect;

  Future<void> _open(BuildContext context) async {
    final picked = await showDialog<ReminderInterval>(
      context: context,
      builder: (ctx) =>
          _IntervalPickerDialog(label: label, initial: value),
    );
    if (picked != null) onSelect(picked);
  }

  @override
  Widget build(BuildContext context) {
    return NbValueRow(
      label: label,
      value: value.label.toUpperCase(),
      onTap: () => _open(context),
    );
  }
}

class _IntervalPickerDialog extends StatefulWidget {
  const _IntervalPickerDialog({
    required this.label,
    required this.initial,
  });

  final String label;
  final ReminderInterval initial;

  @override
  State<_IntervalPickerDialog> createState() => _IntervalPickerDialogState();
}

class _IntervalPickerDialogState extends State<_IntervalPickerDialog> {
  late bool _enabled;
  late ReminderUnit _unit;
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initial.enabled;
    _unit = widget.initial.unit;
    _countController =
        TextEditingController(text: widget.initial.count.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _save() {
    final raw = int.tryParse(_countController.text.trim());
    final count = (raw == null || raw < 1) ? 1 : raw;
    Navigator.of(context).pop(
      ReminderInterval(enabled: _enabled, count: count, unit: _unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
            color: AppColors.border, width: NbStyles.borderWidth),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.label.toUpperCase(), style: AppTextStyles.title),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Enable reminders',
                        style: AppTextStyles.body),
                  ),
                  NbSwitch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _enabled ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_enabled,
                  child: Row(
                    children: [
                      Text('Every', style: AppTextStyles.body),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 72,
                        child: TextField(
                          controller: _countController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: AppTextStyles.body,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _UnitDropdown(
                        value: _unit,
                        count:
                            int.tryParse(_countController.text) ?? 1,
                        onChanged: (v) => setState(() => _unit = v),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NbButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppColors.surface,
                      expand: true,
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NbButton(
                      onPressed: _save,
                      color: AppColors.primary,
                      expand: true,
                      child: const Text('SAVE'),
                    ),
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

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.value,
    required this.count,
    required this.onChanged,
  });

  final ReminderUnit value;
  final int count;
  final ValueChanged<ReminderUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
            color: AppColors.border, width: NbStyles.borderWidth),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReminderUnit>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.onSurface,
          style: AppTextStyles.body,
          items: ReminderUnit.values
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u.labelFor(count)),
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
