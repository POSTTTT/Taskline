import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global brightness used by [AppColors] / [AppTextStyles] / [NbStyles] to
/// resolve theme-dependent values. Updated from the settings screen, listened
/// to by `TasklineApp` to rebuild the tree.
final ValueNotifier<Brightness> appBrightness =
    ValueNotifier<Brightness>(Brightness.light);

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

/// Light "paper terminal" palette — warm paper with the same amber accent, for
/// users who want a bright variant of the CLI look.
class _LightPalette {
  static const Color background = Color(0xFFF2EFE6); // warm paper
  static const Color surface = Color(0xFFFBF9F1); // lifted panel
  static const Color surfaceVariant = Color(0xFFECE6D8);
  static const Color border = Color(0xFFD8D0BF); // hairline
  static const Color primary = Color(0xFFC8851A); // deep amber (reads on light)
  static const Color primaryDark = Color(0xFFA66E12);
  static const Color secondary = Color(0xFF2E8C7C); // teal accent
  static const Color destructive = Color(0xFFC2503C);
  static const Color success = Color(0xFF2E8C7C);
  static const Color warning = Color(0xFFB26A00);
  static const Color onSurface = Color(0xFF211C12);
  static const Color onSurfaceMuted = Color(0xFF5B5546);
  static const Color onSurfaceFaint = Color(0xFF8A8470);
  static const Color shadow = Color(0x1F000000);
  // Content sitting on a bright accent fill (button labels, checkmarks).
  static const Color onPrimary = Color(0xFF1A1304);
}

/// Dark CLI palette — amber/gold on a warm near-black tube. The hero look:
/// faint lifted panels, hairline borders, a soft amber glow on the active
/// element. Modelled on a modern terminal dashboard.
class _DarkPalette {
  static const Color background = Color(0xFF0D0D0C); // warm near-black
  static const Color surface = Color(0xFF161513); // faint lifted panel
  static const Color surfaceVariant = Color(0xFF1F1D1A);
  static const Color border = Color(0xFF2C2824); // warm hairline
  static const Color primary = Color(0xFFE9A93C); // amber / gold
  static const Color primaryDark = Color(0xFFC8902E);
  static const Color secondary = Color(0xFF46B3A0); // teal accent
  static const Color destructive = Color(0xFFE06C5A); // warm red
  static const Color success = Color(0xFF46B3A0);
  static const Color warning = Color(0xFFE9A93C);
  static const Color onSurface = Color(0xFFE5E0D6); // warm off-white body
  static const Color onSurfaceMuted = Color(0xFF9C968B); // warm gray meta
  static const Color onSurfaceFaint = Color(0xFF6E6A62);
  static const Color shadow = Color(0x66000000);
  static const Color onPrimary = Color(0xFF1A1304); // dark text on amber
}

/// Terminal palette wrapper. Static getters resolve to the light or dark
/// palette depending on [appBrightness].
class AppColors {
  AppColors._();

  static bool get _dark => appBrightness.value == Brightness.dark;

  static Color get background =>
      _dark ? _DarkPalette.background : _LightPalette.background;
  static Color get surface =>
      _dark ? _DarkPalette.surface : _LightPalette.surface;
  static Color get surfaceVariant =>
      _dark ? _DarkPalette.surfaceVariant : _LightPalette.surfaceVariant;
  static Color get border =>
      _dark ? _DarkPalette.border : _LightPalette.border;

  static Color get primary =>
      _dark ? _DarkPalette.primary : _LightPalette.primary;
  static Color get primaryDark =>
      _dark ? _DarkPalette.primaryDark : _LightPalette.primaryDark;
  static Color get secondary =>
      _dark ? _DarkPalette.secondary : _LightPalette.secondary;
  static Color get destructive =>
      _dark ? _DarkPalette.destructive : _LightPalette.destructive;
  static Color get success =>
      _dark ? _DarkPalette.success : _LightPalette.success;
  static Color get warning =>
      _dark ? _DarkPalette.warning : _LightPalette.warning;

  static Color get onSurface =>
      _dark ? _DarkPalette.onSurface : _LightPalette.onSurface;
  static Color get onSurfaceMuted =>
      _dark ? _DarkPalette.onSurfaceMuted : _LightPalette.onSurfaceMuted;
  static Color get onSurfaceFaint =>
      _dark ? _DarkPalette.onSurfaceFaint : _LightPalette.onSurfaceFaint;

  /// Near-black foreground for content placed on a bright accent fill
  /// (amber / teal / red). Reads on all of them in both modes.
  static Color get onPrimary =>
      _dark ? _DarkPalette.onPrimary : _LightPalette.onPrimary;

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

  static Color get shadowColor => appBrightness.value == Brightness.dark
      ? _DarkPalette.shadow
      : _LightPalette.shadow;

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
