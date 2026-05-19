import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

enum _Section { notification, timeFormat, theme }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Section? _expanded = _Section.notification;

  void _toggle(_Section s) {
    setState(() {
      _expanded = _expanded == s ? null : s;
    });
  }

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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Setting',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _SettingsSection(
                      title: 'Notification',
                      expanded: _expanded == _Section.notification,
                      onToggle: () => _toggle(_Section.notification),
                      child: _NotificationSettings(
                        settings: settings,
                        onChanged: _save,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsSection(
                      title: 'Time format',
                      expanded: _expanded == _Section.timeFormat,
                      onToggle: () => _toggle(_Section.timeFormat),
                      child: _TimeFormatSettings(
                        settings: settings,
                        onChanged: _save,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsSection(
                      title: 'Theme',
                      expanded: _expanded == _Section.theme,
                      onToggle: () => _toggle(_Section.theme),
                      child: const _ThemeSettings(),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: onBack,
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: expanded
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.arrow_drop_down
                        : Icons.play_arrow_rounded,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <_IntervalRowData>[
      _IntervalRowData(
        label: 'More than 1 year',
        value: settings.moreThan1Year,
        onSelect: (v) => onChanged(settings.copyWith(moreThan1Year: v)),
      ),
      _IntervalRowData(
        label: 'Due in 1 year',
        value: settings.dueIn1Year,
        onSelect: (v) => onChanged(settings.copyWith(dueIn1Year: v)),
      ),
      _IntervalRowData(
        label: 'Due in 1 month',
        value: settings.dueIn1Month,
        onSelect: (v) => onChanged(settings.copyWith(dueIn1Month: v)),
      ),
      _IntervalRowData(
        label: 'Due in 1 week',
        value: settings.dueIn1Week,
        onSelect: (v) => onChanged(settings.copyWith(dueIn1Week: v)),
      ),
      _IntervalRowData(
        label: 'Due in 1 day',
        value: settings.dueIn1Day,
        onSelect: (v) => onChanged(settings.copyWith(dueIn1Day: v)),
      ),
      _IntervalRowData(
        label: 'Due in 1 hour',
        value: settings.dueIn1Hour,
        onSelect: (v) => onChanged(settings.copyWith(dueIn1Hour: v)),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _IntervalRow(data: rows[i]),
            if (i != rows.length - 1)
              const Divider(color: AppColors.divider, height: 0),
          ],
        ],
      ),
    );
  }
}

class _IntervalRowData {
  _IntervalRowData({
    required this.label,
    required this.value,
    required this.onSelect,
  });
  final String label;
  final ReminderInterval value;
  final ValueChanged<ReminderInterval> onSelect;
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({required this.data});

  final _IntervalRowData data;

  Future<void> _open(BuildContext context) async {
    final picked = await showDialog<ReminderInterval>(
      context: context,
      builder: (ctx) => _IntervalPickerDialog(
        label: data.label,
        initial: data.value,
      ),
    );
    if (picked != null) data.onSelect(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          Material(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => _open(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.value.label,
                      style: TextStyle(
                        color: data.value.enabled
                            ? AppColors.onSurface
                            : AppColors.onSurfaceMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Enable reminders',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: _enabled ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_enabled,
                  child: Row(
                    children: [
                      const Text(
                        'Every',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 14,
                        ),
                      ),
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
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
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
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReminderUnit>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant,
          iconEnabledColor: AppColors.onSurface,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
          ),
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

class _TimeFormatSettings extends StatelessWidget {
  const _TimeFormatSettings({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          _SettingRow<TimeFormatPref>(
            label: 'Time format',
            value: settings.timeFormat,
            labelOf: (v) => v.label,
            options: TimeFormatPref.values,
            onSelected: (v) => onChanged(settings.copyWith(timeFormat: v)),
          ),
          const Divider(color: AppColors.divider, height: 0),
          _SettingRow<DateFormatPref>(
            label: 'Year format',
            value: settings.dateFormat,
            labelOf: (v) => v.label,
            options: DateFormatPref.values,
            onSelected: (v) => onChanged(settings.copyWith(dateFormat: v)),
          ),
        ],
      ),
    );
  }
}

class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: const Column(
        children: [
          _SettingRow<String>(
            label: 'App theme',
            value: 'Dark',
            labelOf: _identity,
            options: ['Dark'],
            onSelected: null,
            disabledHint: 'More themes coming soon',
          ),
        ],
      ),
    );
  }
}

String _identity(String s) => s;

class _SettingRow<T> extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.labelOf,
    required this.options,
    required this.onSelected,
    this.disabledHint,
  });

  final String label;
  final T value;
  final String Function(T) labelOf;
  final List<T> options;
  final ValueChanged<T>? onSelected;
  final String? disabledHint;

  Future<void> _openPicker(BuildContext context) async {
    if (onSelected == null) return;
    final picked = await showDialog<T>(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ...options.map(
                    (o) => ListTile(
                      title: Text(
                        labelOf(o),
                        style: const TextStyle(color: AppColors.onSurface),
                      ),
                      trailing: o == value
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(o),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked != null && picked != value) onSelected!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          if (!enabled && disabledHint != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                disabledHint!,
                style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ),
          Material(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: enabled ? () => _openPicker(context) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelOf(value),
                      style: TextStyle(
                        color: enabled
                            ? AppColors.onSurface
                            : AppColors.onSurfaceMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: enabled
                          ? AppColors.onSurfaceMuted
                          : AppColors.divider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
