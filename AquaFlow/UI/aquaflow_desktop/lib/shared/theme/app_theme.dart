import 'package:flutter/material.dart';

/// Brand colors for the AquaFlow client. Restricted to the approved brand
/// palette only - do not introduce colors outside this set.
class AppColors {
  AppColors._();

  /// Deep navy blue - primary brand color (app bar, buttons, logo wordmark).
  static const Color primary = Color(0xFF06356C);

  /// Bright sky blue accent (logo droplet, links, highlights).
  static const Color secondary = Color(0xFF2FA6F6);

  /// Warning / call-out accent.
  static const Color warning = Color(0xFFF59E0B);

  /// Primary text color on light surfaces.
  static const Color textDark = Color(0xFF1F2937);

  /// Success accent (confirmations, positive status).
  static const Color success = Color(0xFF22C55E);

  /// Off-white app background so screens are not stark white.
  static const Color background = Color(0xFFF5FAFF);

  /// Fill color for input fields so they read on a white card.
  static const Color inputFill = Color(0xFFF5FAFF);

  /// Selected-tab indicator in the bottom navigation bar (tinted secondary).
  static const Color navIndicator = Color(0x402FA6F6);

  /// Diagonal gradient painted behind the login/register screens.
  static const List<Color> waterGradient = [
    Color(0xFF06356C),
    Color(0xFF2FA6F6),
  ];

  /// Gradient for the primary call-to-action button (navy -> sky blue).
  static const List<Color> buttonGradient = [
    Color(0xFF06356C),
    Color(0xFF2FA6F6),
  ];
}

/// Central [ThemeData] for the app. Referenced once from `main.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      secondary: AppColors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.navIndicator,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x332FA6F6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      secondary: AppColors.secondary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.textDark,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
