import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.success,
      tertiary: AppColors.warning,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      error: AppColors.danger,
    );

    return _buildTheme(
      brightness: Brightness.dark,
      scheme: scheme,
      scaffold: AppColors.background,
      card: AppColors.surface,
      elevated: AppColors.surfaceElevated,
      border: AppColors.border,
      muted: AppColors.textMuted,
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.success,
      tertiary: AppColors.warning,
      surface: AppColors.lightSurface,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      error: AppColors.danger,
    );

    return _buildTheme(
      brightness: Brightness.light,
      scheme: scheme,
      scaffold: AppColors.lightBackground,
      card: AppColors.lightSurface,
      elevated: AppColors.lightSurfaceElevated,
      border: AppColors.lightBorder,
      muted: AppColors.lightTextMuted,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color elevated,
    required Color border,
    required Color muted,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: border,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.display.copyWith(color: scheme.onSurface),
        headlineSmall:
            AppTextStyles.titleLarge.copyWith(color: scheme.onSurface),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: scheme.onSurface),
        titleMedium:
            AppTextStyles.titleMedium.copyWith(color: scheme.onSurface),
        titleSmall:
            AppTextStyles.titleSmall.copyWith(color: scheme.onSurface),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: scheme.onSurface),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
        bodySmall:
            AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        labelLarge: AppTextStyles.button.copyWith(color: scheme.onSurface),
        labelMedium: AppTextStyles.label.copyWith(color: scheme.onSurface),
        labelSmall: AppTextStyles.caption.copyWith(color: muted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumRadius,
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
          textStyle: AppTextStyles.button,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(44, 44),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
          textStyle: AppTextStyles.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: muted),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: muted),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumRadius,
          side: BorderSide(color: border),
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: card,
        indicatorColor: scheme.primary.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: scheme.primary.withOpacity(0.14),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: AppTextStyles.label.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelTextStyle: AppTextStyles.label.copyWith(color: muted),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: muted,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: scheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    );
  }
}
