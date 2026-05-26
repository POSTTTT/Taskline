/// Neo-brutalist widget primitives shared by all screens.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bordered card with a hard offset drop shadow. The signature
/// neo-brutalist container.
class NbCard extends StatelessWidget {
  const NbCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.radius = AppRadii.card,
    this.shadowOffset = NbStyles.shadowOffset,
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Offset shadowOffset;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NbStyles.boxedCard(
        fill: color ?? AppColors.surface,
        radius: radius,
        shadowOffset: shadowOffset,
        borderColor: borderColor ?? AppColors.border,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Primary action button: colored fill, thick black border, hard shadow.
/// Press effect "depresses" the button by collapsing the shadow.
class NbButton extends StatefulWidget {
  const NbButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.borderColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.expand = false,
    this.shadowOffset = NbStyles.shadowOffset,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final bool expand;
  final Offset shadowOffset;

  @override
  State<NbButton> createState() => _NbButtonState();
}

class _NbButtonState extends State<NbButton> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;
  bool get _active => _pressed && _enabled;

  @override
  Widget build(BuildContext context) {
    final offset = _active ? Offset.zero : widget.shadowOffset;
    final translate =
        _active ? widget.shadowOffset : Offset.zero;
    final fill = widget.color ?? AppColors.primary;
    final border = widget.borderColor ?? AppColors.border;
    final fg = widget.foregroundColor ?? AppColors.onSurface;

    return MouseRegion(
      cursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(translate.dx, translate.dy, 0),
          decoration: BoxDecoration(
            color: _enabled
                ? (_hovered && !_active ? _lighten(fill) : fill)
                : Colors.grey.shade300,
            border: Border.all(
              color: border,
              width: NbStyles.borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(
                color: NbStyles.shadowColor,
                offset: offset,
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          alignment: widget.expand ? Alignment.center : null,
          child: DefaultTextStyle.merge(
            style: AppTextStyles.button.copyWith(color: fg),
            child: IconTheme(
              data: IconThemeData(color: fg),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  static Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    final lighter =
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0));
    return lighter.toColor();
  }
}

/// Square checkbox with thick border. Checked state fills with the primary
/// accent and shows a bold check.
class NbCheckbox extends StatelessWidget {
  const NbCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surface,
          border: Border.all(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.circular(2),
        ),
        child: value
            ? Icon(Icons.check, size: size * 0.7, color: AppColors.border)
            : null,
      ),
    );
  }
}

/// Chunky on/off switch. Thumb is a black square that slides between two
/// positions; track is white when off, yellow when on.
class NbSwitch extends StatelessWidget {
  const NbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    const trackWidth = 52.0;
    const trackHeight = 28.0;
    const thumbSize = 18.0;
    const innerPadding = 3.0;

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surface,
          border: Border.all(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.circular(4),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: innerPadding),
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small square icon-only button. Used for circular FAB equivalents and
/// row-level actions like delete.
class NbIconButton extends StatelessWidget {
  const NbIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.iconColor,
    this.size = 40,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppColors.surface;
    final ic = iconColor ?? AppColors.onSurface;
    final btn = NbButton(
      onPressed: onPressed,
      color: fill,
      foregroundColor: ic,
      padding: EdgeInsets.zero,
      shadowOffset: NbStyles.shadowOffsetSmall,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: ic, size: size * 0.55),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

/// Two-option segmented control. Selected option gets the yellow fill +
/// hard shadow; unselected stays flat white with the same border.
class NbSegmentedControl<T> extends StatelessWidget {
  const NbSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: _Segment(
              label: labelOf(o),
              selected: o == value,
              onTap: () => onChanged(o),
            ),
          ),
          if (o != options.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NbButton(
      onPressed: onTap,
      color: selected ? AppColors.primary : AppColors.surface,
      shadowOffset: selected
          ? NbStyles.shadowOffsetSmall
          : const Offset(2, 2),
      padding: const EdgeInsets.symmetric(vertical: 12),
      expand: true,
      child: Text(label),
    );
  }
}

/// Tappable value pill (label-on-left, current value-on-right) used by
/// settings rows and labelled selectors.
class NbValueRow extends StatelessWidget {
  const NbValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                border: Border.all(
                    color: AppColors.border, width: NbStyles.borderWidth),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: AppTextStyles.subhead.copyWith(
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
