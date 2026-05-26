import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global brightness used by [AppColors] / [AppTextStyles] / [NbStyles] to
/// resolve theme-dependent values. Updated from the settings screen, listened
/// to by `TasklineApp` to rebuild the tree.
final ValueNotifier<Brightness> appBrightness =
    ValueNotifier<Brightness>(Brightness.light);

class _LightPalette {
  static const Color background = Color(0xFFFEFCE8); // cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF7B2); // light yellow tint
  static const Color border = Color(0xFF000000);
  static const Color primary = Color(0xFFFFD700); // signature yellow
  static const Color primaryDark = Color(0xFFE6B800);
  static const Color secondary = Color(0xFFA7F432); // lime accent
  static const Color destructive = Color(0xFFFF6B6B);
  static const Color success = Color(0xFFA7F432);
  static const Color warning = Color(0xFFFF9F1C);
  static const Color onSurface = Color(0xFF000000);
  static const Color onSurfaceMuted = Color(0xFF3F3F46);
  static const Color onSurfaceFaint = Color(0xFF71717A);
  static const Color shadow = Color(0xFF000000);
}

class _DarkPalette {
  // Warm near-black background so the cream/yellow brand still feels at home.
  static const Color background = Color(0xFF14140E);
  static const Color surface = Color(0xFF1F1F17);
  // Subtly tinted darker yellow for the "secondary" surface (matches the
  // light theme's light-yellow tint role).
  static const Color surfaceVariant = Color(0xFF3A2F00);
  // Off-white border replaces pure black so cards still read as outlined.
  static const Color border = Color(0xFFF5F5F0);
  static const Color primary = Color(0xFFFFD700); // yellow stays — brand
  static const Color primaryDark = Color(0xFFE6B800);
  static const Color secondary = Color(0xFFA7F432);
  static const Color destructive = Color(0xFFFF6B6B);
  static const Color success = Color(0xFFA7F432);
  static const Color warning = Color(0xFFFF9F1C);
  static const Color onSurface = Color(0xFFF5F5F0);
  static const Color onSurfaceMuted = Color(0xFFB5B5B0);
  static const Color onSurfaceFaint = Color(0xFF808076);
  // Shadows in dark mode use the off-white so the hard offset stays visible.
  static const Color shadow = Color(0xFFF5F5F0);
}

/// Neo-brutalist palette wrapper. Static getters resolve to the light or
/// dark palette depending on [appBrightness].
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
  static Color get groupedHeader => onSurface;

  // Backwards-compat alias used by some old call sites.
  static Color get divider => border;
}

class AppRadii {
  AppRadii._();

  /// Slight rounding only — keeps the brutalist sharp feel while avoiding
  /// jagged single-pixel corners at small sizes.
  static const double card = 4;
  static const double pill = 6;
  static const double inputField = 4;
}

/// Neo-brutalist shadow/border atoms reused by widgets.
class NbStyles {
  NbStyles._();

  static const double borderWidth = 2.5;
  static const Offset shadowOffset = Offset(4, 4);
  static const Offset shadowOffsetSmall = Offset(3, 3);

  static Color get shadowColor =>
      appBrightness.value == Brightness.dark
          ? _DarkPalette.shadow
          : _LightPalette.shadow;

  static BorderSide get blackBorder =>
      BorderSide(color: AppColors.border, width: borderWidth);

  static BoxDecoration boxedCard({
    Color? fill,
    double radius = AppRadii.card,
    Offset shadowOffset = NbStyles.shadowOffset,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: fill ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border:
          Border.all(color: borderColor ?? AppColors.border, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: shadowOffset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get largeTitle => TextStyle(
        color: AppColors.onSurface,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.05,
      );

  static TextStyle get title => TextStyle(
        color: AppColors.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      );

  static TextStyle get body => TextStyle(
        color: AppColors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subhead => TextStyle(
        color: AppColors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get footnote => TextStyle(
        color: AppColors.onSurfaceMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get sectionHeader => TextStyle(
        color: AppColors.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      );

  static TextStyle get button => TextStyle(
        color: AppColors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );
}

ThemeData buildAppTheme() {
  final dark = appBrightness.value == Brightness.dark;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.primary,
    onPrimary: _LightPalette.onSurface, // yellow needs black text either way
    secondary: AppColors.secondary,
    onSecondary: _LightPalette.onSurface,
    error: AppColors.destructive,
    onError: AppColors.onSurface,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceMuted,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
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
      hintStyle: TextStyle(
          color: AppColors.onSurfaceFaint, fontWeight: FontWeight.w600),
      labelStyle: TextStyle(
          color: AppColors.onSurfaceMuted, fontWeight: FontWeight.w700),
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
        borderSide: BorderSide(color: AppColors.primary, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: BorderSide(color: AppColors.destructive, width: 3),
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
