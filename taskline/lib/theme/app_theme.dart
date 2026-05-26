import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Neo-brutalist palette: cream background, white cards with thick black
/// borders, bright yellow primary, hard offset shadows.
class AppColors {
  AppColors._();

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
  static const Color groupedHeader = Color(0xFF000000);

  // Backwards-compat alias used by some old call sites.
  static const Color divider = Color(0xFF000000);
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
  static const Color shadowColor = Colors.black;

  static const BorderSide blackBorder =
      BorderSide(color: AppColors.border, width: borderWidth);

  static BoxDecoration boxedCard({
    Color fill = AppColors.surface,
    double radius = AppRadii.card,
    Offset shadowOffset = NbStyles.shadowOffset,
    Color borderColor = AppColors.border,
  }) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
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

  static const TextStyle largeTitle = TextStyle(
    color: AppColors.onSurface,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.05,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.onSurface,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.onSurface,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle subhead = TextStyle(
    color: AppColors.onSurface,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle footnote = TextStyle(
    color: AppColors.onSurfaceMuted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.onSurface,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static const TextStyle button = TextStyle(
    color: AppColors.onSurface,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onSurface,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSurface,
    error: AppColors.destructive,
    onError: AppColors.onSurface,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceMuted,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: const TextTheme(
      titleLarge: AppTextStyles.largeTitle,
      titleMedium: AppTextStyles.title,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.subhead,
      bodySmall: AppTextStyles.footnote,
      labelLarge: AppTextStyles.button,
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
          color: AppColors.onSurfaceFaint, fontWeight: FontWeight.w600),
      labelStyle: const TextStyle(
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
        borderSide: const BorderSide(color: AppColors.primary, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: const BorderSide(color: AppColors.destructive, width: 3),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border, width: NbStyles.borderWidth),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
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
