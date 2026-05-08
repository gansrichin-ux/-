part of '../../main_site.dart';

ThemeData _buildLightTheme() {
  const seed = Color(0xFF2563EB);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: seed,
    secondary: const Color(0xFF0F766E),
    tertiary: const Color(0xFFB45309),
    surface: Color(0xFFFFFFFF),
  );

  return _buildTheme(
    scheme: scheme,
    scaffold: const Color(0xFFF6F8FB),
    card: Colors.white,
    border: const Color(0xFFD8DEE8),
    muted: const Color(0xFF64748B),
  );
}

ThemeData _buildDarkTheme() {
  const seed = Color(0xFF60A5FA);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    primary: seed,
    secondary: const Color(0xFF2DD4BF),
    tertiary: const Color(0xFFFBBF24),
    surface: const Color(0xFF15161A),
  );

  return _buildTheme(
    scheme: scheme,
    scaffold: const Color(0xFF0E0F12),
    card: const Color(0xFF17191E),
    border: const Color(0xFF2A2E36),
    muted: const Color(0xFFA1A8B3),
  );
}

ThemeData _buildTheme({
  required ColorScheme scheme,
  required Color scaffold,
  required Color card,
  required Color border,
  required Color muted,
}) {
  const fontFamily = 'Segoe UI';
  const fontFallback = ['Arial', 'Roboto', 'sans-serif'];
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
  );

  return base.copyWith(
    textTheme: _buildSiteTextTheme(
      base.textTheme,
      scheme: scheme,
      muted: muted,
    ),
    primaryTextTheme: _buildSiteTextTheme(
      base.primaryTextTheme,
      scheme: scheme,
      muted: muted,
    ),
    cardColor: card,
    dividerColor: border,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        color: scheme.onSurface,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.button.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: border),
        textStyle: AppTextStyles.button.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: muted),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: muted),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: card,
      indicatorColor: scheme.primary.withOpacity(0.14),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSurface,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: 13,
        height: 1.25,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: muted,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: 13,
        height: 1.25,
        letterSpacing: 0,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

TextTheme _buildSiteTextTheme(
  TextTheme base, {
  required ColorScheme scheme,
  required Color muted,
}) {
  return base.copyWith(
    displayLarge: AppTextStyles.display.copyWith(color: scheme.onSurface),
    displayMedium: AppTextStyles.display.copyWith(
      color: scheme.onSurface,
      fontSize: 36,
      height: 1.1,
    ),
    headlineLarge: AppTextStyles.titleLarge.copyWith(
      color: scheme.onSurface,
      fontSize: 32,
    ),
    headlineMedium: AppTextStyles.titleLarge.copyWith(
      color: scheme.onSurface,
    ),
    headlineSmall: AppTextStyles.titleMedium.copyWith(
      color: scheme.onSurface,
      fontSize: 22,
    ),
    titleLarge: AppTextStyles.titleMedium.copyWith(color: scheme.onSurface),
    titleMedium: AppTextStyles.titleSmall.copyWith(color: scheme.onSurface),
    titleSmall: AppTextStyles.label.copyWith(color: scheme.onSurface),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: scheme.onSurface),
    bodyMedium: AppTextStyles.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    ),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: muted),
    labelLarge: AppTextStyles.button.copyWith(color: scheme.onSurface),
    labelMedium: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
    labelSmall: AppTextStyles.caption.copyWith(color: muted),
  );
}
