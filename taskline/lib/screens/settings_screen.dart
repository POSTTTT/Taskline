import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: CupertinoButton(
          padding: const EdgeInsets.only(left: 16),
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chevron_back, color: AppColors.primary),
              SizedBox(width: 2),
              Text('Back', style: TextStyle(color: AppColors.primary, fontSize: 17)),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Text('Settings', style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader('Notifications'),
          _GroupedSection(
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
                onSelect: (v) => _save(settings.copyWith(dueIn1Year: v)),
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
                onSelect: (v) => _save(settings.copyWith(dueIn1Week: v)),
              ),
              const _CellDivider(),
              _IntervalRow(
                label: 'Due in 1 day',
                value: settings.dueIn1Day,
                onSelect: (v) => _save(settings.copyWith(dueIn1Day: v)),
              ),
              const _CellDivider(),
              _IntervalRow(
                label: 'Due in 1 hour',
                value: settings.dueIn1Hour,
                onSelect: (v) => _save(settings.copyWith(dueIn1Hour: v)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Display'),
          _GroupedSection(
            children: [
              _ChoiceRow<TimeFormatPref>(
                label: 'Time format',
                value: settings.timeFormat,
                labelOf: (v) => v.label,
                options: TimeFormatPref.values,
                onSelected: (v) =>
                    _save(settings.copyWith(timeFormat: v)),
              ),
              const _CellDivider(),
              _ChoiceRow<DateFormatPref>(
                label: 'Date format',
                value: settings.dateFormat,
                labelOf: (v) => v.label,
                options: DateFormatPref.values,
                onSelected: (v) =>
                    _save(settings.copyWith(dateFormat: v)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('General'),
          _GroupedSection(
            children: [
              _SwitchRow(
                label: 'Launch at startup',
                value: settings.launchAtStartup,
                onChanged: (v) =>
                    _save(settings.copyWith(launchAtStartup: v)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Appearance'),
          _GroupedSection(
            children: const [
              _StaticRow(
                label: 'Theme',
                value: 'Light',
                trailing: _MutedChevron(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'More themes coming soon.',
              style: AppTextStyles.footnote,
            ),
          ),
        ],
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

class _StaticRow extends StatelessWidget {
  const _StaticRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.body),
          const Spacer(),
          Text(value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.onSurfaceMuted,
              )),
          const SizedBox(width: 6),
          trailing,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MutedChevron extends StatelessWidget {
  const _MutedChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      CupertinoIcons.chevron_right,
      size: 14,
      color: AppColors.onSurfaceFaint,
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
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              Text(
                value.label,
                style: AppTextStyles.body.copyWith(
                  color: value.enabled
                      ? AppColors.onSurfaceMuted
                      : AppColors.onSurfaceFaint,
                ),
              ),
              const SizedBox(width: 6),
              const _MutedChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.labelOf,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T value;
  final String Function(T) labelOf;
  final List<T> options;
  final ValueChanged<T> onSelected;

  Future<void> _open(BuildContext context) async {
    final picked = await showCupertinoModalPopup<T>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(label),
        actions: [
          for (final o in options)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(o),
              isDefaultAction: o == value,
              child: Text(labelOf(o)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (picked != null && picked != value) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              Text(
                labelOf(value),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: 6),
              const _MutedChevron(),
            ],
          ),
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: AppTextStyles.title),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text('Enable reminders', style: AppTextStyles.body),
                  ),
                  CupertinoSwitch(
                    value: _enabled,
                    activeTrackColor: AppColors.success,
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
                      const Text('Every', style: AppTextStyles.body),
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
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UnitDropdown(
                          value: _unit,
                          count: int.tryParse(_countController.text) ?? 1,
                          onChanged: (v) => setState(() => _unit = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReminderUnit>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.onSurfaceMuted,
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
