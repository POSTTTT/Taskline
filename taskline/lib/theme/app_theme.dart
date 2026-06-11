import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';

/// Global brightness used by [AppColors] / [AppTextStyles] / [NbStyles] to
/// resolve theme-dependent values. Updated from the settings screen, listened
/// to by `TasklineApp` to rebuild the tree.
final ValueNotifier<Brightness> appBrightness =
    ValueNotifier<Brightness>(Brightness.light);

/// Global accent palette. Brightness picks light vs dark *within* the chosen
/// palette; this picks the colour family (amber / green / cyan / magenta).
/// Updated from the settings screen, listened to by `TasklineApp`.
final ValueNotifier<TerminalPalette> appPalette =
    ValueNotifier<TerminalPalette>(kPalettes.first);

/// Monospace type stack. The defining signal of the terminal aesthetic — a
/// system monospace on every platform we ship to, with a generic fallback.
const String kMonoFamily = 'Consolas';
const List<String> kMonoFallback = <String>[
  'Consolas',
  'Cascadia Mono',
  'Courier New',
  'Roboto Mono',
  'monospace',
];

/// A complete set of terminal colours for one brightness of one palette. The
/// neutrals are subtly tinted toward the accent so each palette reads as a
/// cohesive CRT phosphor rather than an accent bolted onto grey.
class TerminalColors {
  const TerminalColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceFaint,
    required this.shadow,
    required this.onPrimary,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceFaint;
  final Color shadow;

  /// Content sitting on a bright accent fill (button labels, checkmarks).
  final Color onPrimary;
}

/// A named accent scheme with a light + dark variant. [id] matches the
/// [PalettePref] enum name so settings can round-trip by string.
class TerminalPalette {
  const TerminalPalette({
    required this.id,
    required this.label,
    required this.dark,
    required this.light,
  });

  final String id;
  final String label;
  final TerminalColors dark;
  final TerminalColors light;
}

// ── Amber — gold on a warm near-black tube (the original hero look). ─────────
const TerminalColors _amberDark = TerminalColors(
  background: Color(0xFF0D0D0C),
  surface: Color(0xFF161513),
  surfaceVariant: Color(0xFF1F1D1A),
  border: Color(0xFF2C2824),
  primary: Color(0xFFE9A93C),
  primaryDark: Color(0xFFC8902E),
  secondary: Color(0xFF46B3A0),
  destructive: Color(0xFFE06C5A),
  success: Color(0xFF46B3A0),
  warning: Color(0xFFE9A93C),
  onSurface: Color(0xFFE5E0D6),
  onSurfaceMuted: Color(0xFF9C968B),
  onSurfaceFaint: Color(0xFF6E6A62),
  shadow: Color(0x66000000),
  onPrimary: Color(0xFF1A1304),
);
const TerminalColors _amberLight = TerminalColors(
  background: Color(0xFFF2EFE6),
  surface: Color(0xFFFBF9F1),
  surfaceVariant: Color(0xFFECE6D8),
  border: Color(0xFFD8D0BF),
  primary: Color(0xFFC8851A),
  primaryDark: Color(0xFFA66E12),
  secondary: Color(0xFF2E8C7C),
  destructive: Color(0xFFC2503C),
  success: Color(0xFF2E8C7C),
  warning: Color(0xFFB26A00),
  onSurface: Color(0xFF211C12),
  onSurfaceMuted: Color(0xFF5B5546),
  onSurfaceFaint: Color(0xFF8A8470),
  shadow: Color(0x1F000000),
  onPrimary: Color(0xFF1A1304),
);

// ── Green — classic phosphor green on near-black. ────────────────────────────
const TerminalColors _greenDark = TerminalColors(
  background: Color(0xFF0A0D0A),
  surface: Color(0xFF121511),
  surfaceVariant: Color(0xFF1A1F17),
  border: Color(0xFF273020),
  primary: Color(0xFF54D77E),
  primaryDark: Color(0xFF3FAE62),
  secondary: Color(0xFFD9A441),
  destructive: Color(0xFFE06C5A),
  success: Color(0xFF54D77E),
  warning: Color(0xFFD9A441),
  onSurface: Color(0xFFD8E0D4),
  onSurfaceMuted: Color(0xFF93998B),
  onSurfaceFaint: Color(0xFF656A60),
  shadow: Color(0x66000000),
  onPrimary: Color(0xFF04140A),
);
const TerminalColors _greenLight = TerminalColors(
  background: Color(0xFFEEF2E8),
  surface: Color(0xFFF8FBF1),
  surfaceVariant: Color(0xFFE6ECDA),
  border: Color(0xFFD0D8C2),
  primary: Color(0xFF2E9E52),
  primaryDark: Color(0xFF247E41),
  secondary: Color(0xFFB26A00),
  destructive: Color(0xFFC2503C),
  success: Color(0xFF2E9E52),
  warning: Color(0xFFB26A00),
  onSurface: Color(0xFF15210F),
  onSurfaceMuted: Color(0xFF4E5B45),
  onSurfaceFaint: Color(0xFF7E8A70),
  shadow: Color(0x1F000000),
  onPrimary: Color(0xFF04140A),
);

// ── Cyan — cool cyan on a blue-black tube. ───────────────────────────────────
const TerminalColors _cyanDark = TerminalColors(
  background: Color(0xFF0A0C0D),
  surface: Color(0xFF111416),
  surfaceVariant: Color(0xFF181D1F),
  border: Color(0xFF243030),
  primary: Color(0xFF40C8E0),
  primaryDark: Color(0xFF2EA6BE),
  secondary: Color(0xFF8E86E0),
  destructive: Color(0xFFE06C5A),
  success: Color(0xFF40C8E0),
  warning: Color(0xFFD9A441),
  onSurface: Color(0xFFD4DEE0),
  onSurfaceMuted: Color(0xFF8B9599),
  onSurfaceFaint: Color(0xFF606A6E),
  shadow: Color(0x66000000),
  onPrimary: Color(0xFF021214),
);
const TerminalColors _cyanLight = TerminalColors(
  background: Color(0xFFE8F1F2),
  surface: Color(0xFFF1FAFB),
  surfaceVariant: Color(0xFFDAE8EA),
  border: Color(0xFFC2D4D6),
  primary: Color(0xFF1693AE),
  primaryDark: Color(0xFF127689),
  secondary: Color(0xFF6A5BC2),
  destructive: Color(0xFFC2503C),
  success: Color(0xFF1693AE),
  warning: Color(0xFFB26A00),
  onSurface: Color(0xFF0F1F21),
  onSurfaceMuted: Color(0xFF45565B),
  onSurfaceFaint: Color(0xFF708589),
  shadow: Color(0x1F000000),
  onPrimary: Color(0xFF021214),
);

// ── Magenta — hot pink on a violet-black tube. ───────────────────────────────
const TerminalColors _magentaDark = TerminalColors(
  background: Color(0xFF0D0A0C),
  surface: Color(0xFF161115),
  surfaceVariant: Color(0xFF1F1A1E),
  border: Color(0xFF302530),
  primary: Color(0xFFE06CC0),
  primaryDark: Color(0xFFBE4F9E),
  secondary: Color(0xFF46B3C8),
  destructive: Color(0xFFE0685A),
  success: Color(0xFF46B3A0),
  warning: Color(0xFFD9A441),
  onSurface: Color(0xFFE0D6DE),
  onSurfaceMuted: Color(0xFF998B96),
  onSurfaceFaint: Color(0xFF6A6068),
  shadow: Color(0x66000000),
  onPrimary: Color(0xFF14040F),
);
const TerminalColors _magentaLight = TerminalColors(
  background: Color(0xFFF2E8EF),
  surface: Color(0xFFFBF1F8),
  surfaceVariant: Color(0xFFECDAE6),
  border: Color(0xFFD8C2D2),
  primary: Color(0xFFB52E88),
  primaryDark: Color(0xFF932470),
  secondary: Color(0xFF2E8C9E),
  destructive: Color(0xFFC2503C),
  success: Color(0xFF2E8C7C),
  warning: Color(0xFFB26A00),
  onSurface: Color(0xFF210F1C),
  onSurfaceMuted: Color(0xFF5B4554),
  onSurfaceFaint: Color(0xFF8A7083),
  shadow: Color(0x1F000000),
  onPrimary: Color(0xFF14040F),
);

/// Registry of selectable palettes. Order is the order shown in the picker.
/// Keep [TerminalPalette.id] in sync with [PalettePref] names.
const List<TerminalPalette> kPalettes = <TerminalPalette>[
  TerminalPalette(
      id: 'amber', label: 'Amber', dark: _amberDark, light: _amberLight),
  TerminalPalette(
      id: 'green', label: 'Green', dark: _greenDark, light: _greenLight),
  TerminalPalette(
      id: 'cyan', label: 'Cyan', dark: _cyanDark, light: _cyanLight),
  TerminalPalette(
      id: 'magenta',
      label: 'Magenta',
      dark: _magentaDark,
      light: _magentaLight),
];

/// Resolves a palette by its [PalettePref]/id, falling back to the first.
TerminalPalette paletteById(String id) =>
    kPalettes.firstWhere((p) => p.id == id, orElse: () => kPalettes.first);

/// Terminal palette wrapper. Static getters resolve to the active palette's
/// light or dark colours, depending on [appPalette] and [appBrightness].
class AppColors {
  AppColors._();

  /// The active colour set — current palette at the current brightness.
  static TerminalColors get current => appBrightness.value == Brightness.dark
      ? appPalette.value.dark
      : appPalette.value.light;

  static Color get background => current.background;
  static Color get surface => current.surface;
  static Color get surfaceVariant => current.surfaceVariant;
  static Color get border => current.border;

  static Color get primary => current.primary;
  static Color get primaryDark => current.primaryDark;
  static Color get secondary => current.secondary;
  static Color get destructive => current.destructive;
  static Color get success => current.success;
  static Color get warning => current.warning;

  static Color get onSurface => current.onSurface;
  static Color get onSurfaceMuted => current.onSurfaceMuted;
  static Color get onSurfaceFaint => current.onSurfaceFaint;

  /// Near-black foreground for content placed on a bright accent fill
  /// (amber / teal / red). Reads on all of them in both modes.
  static Color get onPrimary => current.onPrimary;

  static Color get groupedHeader => onSurface;

  // Backwards-compat alias used by some old call sites.
  static Color get divider => border;
}

class AppRadii {
  AppRadii._();

  /// Gentle rounding — the refined CLI-dashboard look, not razor-sharp.
  static const double card = 6;
  static const double pill = 8;
  static const double inputField = 6;
}

/// Terminal shadow/border atoms reused by widgets. Borders are hairlines and
/// shadows are soft (or amber glows on accent fills) — depth comes from the
/// faint panel fill, not from hard offsets.
class NbStyles {
  NbStyles._();

  static const double borderWidth = 1;
  static const Offset shadowOffset = Offset(0, 2);
  static const Offset shadowOffsetSmall = Offset(0, 1);

  static Color get shadowColor => AppColors.current.shadow;

  static BorderSide get blackBorder =>
      BorderSide(color: AppColors.border, width: borderWidth);

  /// Picks a legible foreground for content sitting on [fill]. Bright fills
  /// (amber, teal, red, light surfaces) get the near-black
  /// [AppColors.onPrimary]; dark fills get the light [AppColors.onSurface].
  /// Centralises contrast so no widget hand-codes a foreground on an accent.
  static Color foregroundOn(Color fill) =>
      fill.computeLuminance() > 0.3 ? AppColors.onPrimary : AppColors.onSurface;

  /// True when [fill] is a bright accent that should carry a soft glow rather
  /// than a drop shadow.
  static bool isAccent(Color fill) => fill.computeLuminance() > 0.3;

  static BoxDecoration boxedCard({
    Color? fill,
    double radius = AppRadii.card,
    Offset shadowOffset = NbStyles.shadowOffset,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: fill ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: borderColor ?? AppColors.border, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: shadowOffset,
          blurRadius: 8,
          spreadRadius: -4,
        ),
      ],
    );
  }
}

class AppTextStyles {
  AppTextStyles._();

  // Monospace fonts top out at a real bold (w700); heavier weights only get
  // synthesised, so the terminal styles cap there.
  static TextStyle _mono({
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: kMonoFamily,
      fontFamilyFallback: kMonoFallback,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle get largeTitle => _mono(
        color: AppColors.onSurface,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.1,
      );

  static TextStyle get title => _mono(
        color: AppColors.primary,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get body => _mono(
        color: AppColors.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get subhead => _mono(
        color: AppColors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get footnote => _mono(
        color: AppColors.onSurfaceMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get sectionHeader => _mono(
        color: AppColors.onSurfaceMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      );

  static TextStyle get button => _mono(
        color: AppColors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
}

ThemeData buildAppTheme() {
  final dark = appBrightness.value == Brightness.dark;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onPrimary,
    error: AppColors.destructive,
    onError: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceMuted,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: kMonoFamily,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.border,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    textTheme: TextTheme(
      titleLarge: AppTextStyles.largeTitle,
      titleMedium: AppTextStyles.title,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.subhead,
      bodySmall: AppTextStyles.footnote,
      labelLarge: AppTextStyles.button,
    ),
    iconTheme: IconThemeData(color: AppColors.onSurface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.onSurfaceFaint),
      labelStyle:
          AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: NbStyles.blackBorder,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: NbStyles.blackBorder,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: BorderSide(color: AppColors.destructive, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border, width: NbStyles.borderWidth),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.card)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        textStyle: AppTextStyles.button,
      ),
    ),
  );
}
