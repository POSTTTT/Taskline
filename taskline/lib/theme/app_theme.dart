import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS-style light palette modeled after Apple Reminders / Things 3.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color surface = Color(0xFFFFFFFF); // grouped section bg
  static const Color surfaceVariant = Color(0xFFE5E5EA); // tertiary system fill

  static const Color primary = Color(0xFF007AFF); // systemBlue
  static const Color destructive = Color(0xFFFF3B30); // systemRed
  static const Color success = Color(0xFF34C759); // systemGreen
  static const Color warning = Color(0xFFFF9500); // systemOrange

  static const Color onSurface = Color(0xFF000000); // label
  static const Color onSurfaceMuted = Color(0x993C3C43); // secondaryLabel ~60%
  static const Color onSurfaceFaint = Color(0x4D3C3C43); // tertiaryLabel ~30%

  static const Color divider = Color(0x5C3C3C43); // separator ~36%
  static const Color groupedHeader = Color(0xFF6C6C70); // header text
}

class AppRadii {
  AppRadii._();

  static const double card = 10; // iOS grouped section radius
  static const double pill = 22;
  static const double inputField = 10;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle largeTitle = TextStyle(
    color: AppColors.onSurface,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.onSurface,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.onSurface,
    fontSize: 17,
  );

  static const TextStyle subhead = TextStyle(
    color: AppColors.onSurface,
    fontSize: 15,
  );

  static const TextStyle footnote = TextStyle(
    color: AppColors.onSurfaceMuted,
    fontSize: 13,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.groupedHeader,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    error: AppColors.destructive,
    onError: Colors.white,
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
    dividerColor: AppColors.divider,
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
    ),
    iconTheme: const IconThemeData(color: AppColors.primary),
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.background,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.onSurfaceFaint),
      labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.success
            : AppColors.surfaceVariant,
      ),
      trackOutlineColor:
          const WidgetStatePropertyAll(Colors.transparent),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
  );
}
