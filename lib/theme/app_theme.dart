import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Use Plus Jakarta Sans as the primary font - clean and readable
TextStyle _fontStyle(double fontSize, FontWeight weight, Color color,
    {double? letterSpacing, double? height}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Professional App Theme - Clean, clinical, trustworthy
class AppTheme {
  // Professional Light Mode Colors - Healthcare/medical aesthetic
  static const lightColors = AppColors(
    // Primary colors - Professional blue
    primary: Color(0xFF2563EB), // Blue - trustworthy, professional
    primaryLight: Color(0xFF3B82F6), // Lighter blue
    primaryDark: Color(0xFF1D4ED8), // Darker blue

    // Secondary colors - Muted teal for accents
    secondary: Color(0xFF0891B2), // Cyan - clinical accent
    secondaryLight: Color(0xFF06B6D4), // Lighter cyan
    secondaryDark: Color(0xFF0E7490), // Darker cyan

    // Background colors - Clean whites and grays
    background: Color(0xFFFAFAFA), // Warm white
    surface: Color(0xFFFFFFFF), // Pure white
    surfaceVariant: Color(0xFFF5F5F5), // Light gray

    // Text colors - High contrast for readability
    textPrimary: Color(0xFF171717), // Near black
    textSecondary: Color(0xFF525252), // Dark gray
    textTertiary: Color(0xFF737373), // Medium gray
    textOnPrimary: Color(0xFFFFFFFF), // White text on primary

    // Status colors - Clear, accessible
    success: Color(0xFF059669), // Green
    warning: Color(0xFFD97706), // Amber
    error: Color(0xFFDC2626), // Red
    info: Color(0xFF2563EB), // Blue (matches primary)

    // Chart colors
    chartLine: Color(0xFF2563EB), // Blue
    chartBar: Color(0xFF0891B2), // Cyan
    chartGradientTop: Color(0xFF3B82F6),
    chartGradientBottom: Color(0xFFDBEAFE),

    // UI element colors - Subtle, professional
    divider: Color(0xFFE5E5E5),
    border: Color(0xFFD4D4D4),
    shadow: Color(0x0A000000),
    cardBackground: Color(0xFFFFFFFF),

    // Navigation colors
    navBackground: Color(0xFFFFFFFF),
    navSelected: Color(0xFF2563EB),
    navUnselected: Color(0xFF737373),

    // Input colors
    inputBackground: Color(0xFFFAFAFA),
    inputBorder: Color(0xFFD4D4D4),
    inputFocusBorder: Color(0xFF2563EB),
  );

  // Professional Dark Mode Colors - Sophisticated, clinical
  static const darkColors = AppColors(
    // Primary colors
    primary: Color(0xFF3B82F6), // Blue for dark mode
    primaryLight: Color(0xFF60A5FA), // Lighter blue
    primaryDark: Color(0xFF2563EB), // Standard blue

    // Secondary colors
    secondary: Color(0xFF06B6D4), // Cyan for dark mode
    secondaryLight: Color(0xFF22D3EE), // Lighter cyan
    secondaryDark: Color(0xFF0891B2), // Standard cyan

    // Background colors - Deep, sophisticated
    background: Color(0xFF0A0A0A), // Near black
    surface: Color(0xFF171717), // Dark gray
    surfaceVariant: Color(0xFF262626), // Medium dark gray

    // Text colors
    textPrimary: Color(0xFFFAFAFA), // Near white
    textSecondary: Color(0xFFA3A3A3), // Light gray
    textTertiary: Color(0xFF737373), // Medium gray
    textOnPrimary: Color(0xFFFFFFFF), // White text on primary

    // Status colors - Accessible on dark
    success: Color(0xFF10B981), // Green
    warning: Color(0xFFF59E0B), // Amber
    error: Color(0xFFEF4444), // Red
    info: Color(0xFF3B82F6), // Blue

    // Chart colors
    chartLine: Color(0xFF3B82F6), // Blue
    chartBar: Color(0xFF06B6D4), // Cyan
    chartGradientTop: Color(0xFF60A5FA),
    chartGradientBottom: Color(0xFF1E3A8A),

    // UI element colors
    divider: Color(0xFF262626),
    border: Color(0xFF404040),
    shadow: Color(0x40000000),
    cardBackground: Color(0xFF171717),

    // Navigation colors
    navBackground: Color(0xFF171717),
    navSelected: Color(0xFF3B82F6),
    navUnselected: Color(0xFF737373),

    // Input colors
    inputBackground: Color(0xFF262626),
    inputBorder: Color(0xFF404040),
    inputFocusBorder: Color(0xFF3B82F6),
  );

  /// Get light theme data
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightColors.primary,
        secondary: lightColors.secondary,
        surface: lightColors.surface,
        error: lightColors.error,
        onPrimary: lightColors.textOnPrimary,
        onSecondary: lightColors.textOnPrimary,
        onSurface: lightColors.textPrimary,
        onError: lightColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: lightColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors.surface,
        foregroundColor: lightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
        ),
      ),
      cardTheme: ThemeData.light().cardTheme.copyWith(
            color: lightColors.cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: lightColors.border),
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors.primary,
          foregroundColor: lightColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: lightColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: lightColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: lightColors.inputFocusBorder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: lightColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: lightColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColors.navBackground,
        selectedItemColor: lightColors.navSelected,
        unselectedItemColor: lightColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColors.primary,
        foregroundColor: lightColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: ThemeData.light().dialogTheme.copyWith(
            backgroundColor: lightColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titleTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: lightColors.textPrimary,
            ),
            contentTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: lightColors.textSecondary,
            ),
          ),
      dividerTheme: DividerThemeData(
        color: lightColors.divider,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(lightColors),
    );
  }

  /// Get dark theme data
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkColors.primary,
        secondary: darkColors.secondary,
        surface: darkColors.surface,
        error: darkColors.error,
        onPrimary: darkColors.textOnPrimary,
        onSecondary: darkColors.textOnPrimary,
        onSurface: darkColors.textPrimary,
        onError: darkColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: darkColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors.surface,
        foregroundColor: darkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
        ),
      ),
      cardTheme: ThemeData.dark().cardTheme.copyWith(
            color: darkColors.cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: darkColors.border),
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors.primary,
          foregroundColor: darkColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: darkColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: darkColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: darkColors.inputFocusBorder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: darkColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: darkColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors.navBackground,
        selectedItemColor: darkColors.navSelected,
        unselectedItemColor: darkColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColors.primary,
        foregroundColor: darkColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: ThemeData.dark().dialogTheme.copyWith(
            backgroundColor: darkColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titleTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkColors.textPrimary,
            ),
            contentTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: darkColors.textSecondary,
            ),
          ),
      dividerTheme: DividerThemeData(
        color: darkColors.divider,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(darkColors),
    );
  }

  static TextTheme _buildTextTheme(AppColors colors) {
    return TextTheme(
      displayLarge: _fontStyle(57, FontWeight.w400, colors.textPrimary),
      displayMedium: _fontStyle(45, FontWeight.w400, colors.textPrimary),
      displaySmall: _fontStyle(36, FontWeight.w400, colors.textPrimary),
      headlineLarge: _fontStyle(32, FontWeight.w700, colors.textPrimary,
          letterSpacing: -0.5),
      headlineMedium: _fontStyle(28, FontWeight.w700, colors.textPrimary,
          letterSpacing: -0.5),
      headlineSmall: _fontStyle(24, FontWeight.w600, colors.textPrimary,
          letterSpacing: -0.3),
      titleLarge: _fontStyle(22, FontWeight.w600, colors.textPrimary,
          letterSpacing: -0.2),
      titleMedium: _fontStyle(16, FontWeight.w600, colors.textPrimary),
      titleSmall: _fontStyle(14, FontWeight.w600, colors.textPrimary),
      bodyLarge:
          _fontStyle(16, FontWeight.w400, colors.textPrimary, height: 1.5),
      bodyMedium:
          _fontStyle(14, FontWeight.w400, colors.textSecondary, height: 1.5),
      bodySmall:
          _fontStyle(12, FontWeight.w400, colors.textTertiary, height: 1.4),
      labelLarge: _fontStyle(14, FontWeight.w600, colors.textPrimary),
      labelMedium: _fontStyle(12, FontWeight.w600, colors.textSecondary),
      labelSmall: _fontStyle(11, FontWeight.w600, colors.textTertiary,
          letterSpacing: 0.3),
    );
  }
}

/// App color scheme holder
class AppColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;

  final Color background;
  final Color surface;
  final Color surfaceVariant;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color chartLine;
  final Color chartBar;
  final Color chartGradientTop;
  final Color chartGradientBottom;

  final Color divider;
  final Color border;
  final Color shadow;
  final Color cardBackground;

  final Color navBackground;
  final Color navSelected;
  final Color navUnselected;

  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBorder;

  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.chartLine,
    required this.chartBar,
    required this.chartGradientTop,
    required this.chartGradientBottom,
    required this.divider,
    required this.border,
    required this.shadow,
    required this.cardBackground,
    required this.navBackground,
    required this.navSelected,
    required this.navUnselected,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBorder,
  });
}

/// Extension to easily access app colors from context
extension AppColorsExtension on BuildContext {
  AppColors get colors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkColors
        : AppTheme.lightColors;
  }

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// Compatibility for Flutter SDKs that do not expose Color.withValues.
extension ColorWithValuesCompatibility on Color {
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
  }) {
    int normalizeToChannel(double component) =>
        (component.clamp(0.0, 1.0) * 255).round();

    // ignore: deprecated_member_use
    final int currentValue = value;
    final int currentAlpha = (currentValue >> 24) & 0xFF;
    final int currentRed = (currentValue >> 16) & 0xFF;
    final int currentGreen = (currentValue >> 8) & 0xFF;
    final int currentBlue = currentValue & 0xFF;

    return Color.fromARGB(
      alpha != null ? normalizeToChannel(alpha) : currentAlpha,
      red != null ? normalizeToChannel(red) : currentRed,
      green != null ? normalizeToChannel(green) : currentGreen,
      blue != null ? normalizeToChannel(blue) : currentBlue,
    );
  }
}
