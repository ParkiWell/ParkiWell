import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern App Theme with sleek color schemes for light and dark modes
class AppTheme {
  // Modern Light Mode Colors - Clean, fresh, professional
  static const lightColors = AppColors(
    // Primary colors
    primary: Color(0xFF6366F1),        // Indigo - main accent
    primaryLight: Color(0xFF818CF8),   // Lighter indigo
    primaryDark: Color(0xFF4F46E5),    // Darker indigo
    
    // Secondary colors
    secondary: Color(0xFF14B8A6),      // Teal - secondary accent
    secondaryLight: Color(0xFF2DD4BF), // Lighter teal
    secondaryDark: Color(0xFF0D9488),  // Darker teal
    
    // Background colors
    background: Color(0xFFF8FAFC),     // Very light gray (almost white)
    surface: Color(0xFFFFFFFF),        // Pure white
    surfaceVariant: Color(0xFFF1F5F9), // Slightly darker surface
    
    // Text colors
    textPrimary: Color(0xFF0F172A),    // Dark slate
    textSecondary: Color(0xFF475569),  // Medium slate
    textTertiary: Color(0xFF94A3B8),   // Light slate
    textOnPrimary: Color(0xFFFFFFFF),  // White text on primary
    
    // Status colors
    success: Color(0xFF10B981),        // Green
    warning: Color(0xFFF59E0B),        // Amber
    error: Color(0xFFEF4444),          // Red
    info: Color(0xFF3B82F6),           // Blue
    
    // Chart colors
    chartLine: Color(0xFF6366F1),      // Indigo
    chartBar: Color(0xFF14B8A6),       // Teal
    chartGradientTop: Color(0xFF818CF8),
    chartGradientBottom: Color(0xFFC7D2FE),
    
    // UI element colors
    divider: Color(0xFFE2E8F0),
    border: Color(0xFFCBD5E1),
    shadow: Color(0x1A000000),
    cardBackground: Color(0xFFFFFFFF),
    
    // Navigation colors
    navBackground: Color(0xFFFFFFFF),
    navSelected: Color(0xFF6366F1),
    navUnselected: Color(0xFF94A3B8),
    
    // Input colors
    inputBackground: Color(0xFFF1F5F9),
    inputBorder: Color(0xFFCBD5E1),
    inputFocusBorder: Color(0xFF6366F1),
  );
  
  // Modern Dark Mode Colors - Deep, rich, elegant
  static const darkColors = AppColors(
    // Primary colors
    primary: Color(0xFF818CF8),        // Lighter indigo for dark mode
    primaryLight: Color(0xFFA5B4FC),   // Even lighter
    primaryDark: Color(0xFF6366F1),    // Standard indigo
    
    // Secondary colors
    secondary: Color(0xFF2DD4BF),      // Brighter teal for dark mode
    secondaryLight: Color(0xFF5EEAD4), // Lighter teal
    secondaryDark: Color(0xFF14B8A6),  // Standard teal
    
    // Background colors
    background: Color(0xFF0F172A),     // Deep slate
    surface: Color(0xFF1E293B),        // Lighter slate
    surfaceVariant: Color(0xFF334155), // Even lighter slate
    
    // Text colors
    textPrimary: Color(0xFFF8FAFC),    // Almost white
    textSecondary: Color(0xFFCBD5E1),  // Light slate
    textTertiary: Color(0xFF64748B),   // Medium slate
    textOnPrimary: Color(0xFF0F172A),  // Dark text on primary
    
    // Status colors
    success: Color(0xFF34D399),        // Brighter green
    warning: Color(0xFFFBBF24),        // Brighter amber
    error: Color(0xFFF87171),          // Brighter red
    info: Color(0xFF60A5FA),           // Brighter blue
    
    // Chart colors
    chartLine: Color(0xFF818CF8),      // Light indigo
    chartBar: Color(0xFF2DD4BF),       // Bright teal
    chartGradientTop: Color(0xFFA5B4FC),
    chartGradientBottom: Color(0xFF4338CA),
    
    // UI element colors
    divider: Color(0xFF334155),
    border: Color(0xFF475569),
    shadow: Color(0x40000000),
    cardBackground: Color(0xFF1E293B),
    
    // Navigation colors
    navBackground: Color(0xFF1E293B),
    navSelected: Color(0xFF818CF8),
    navUnselected: Color(0xFF64748B),
    
    // Input colors
    inputBackground: Color(0xFF334155),
    inputBorder: Color(0xFF475569),
    inputFocusBorder: Color(0xFF818CF8),
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
        scrolledUnderElevation: 1,
        shadowColor: lightColors.shadow,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightColors.border.withOpacity(0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors.primary,
          foregroundColor: lightColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.inputFocusBorder, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
          color: lightColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: lightColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColors.navBackground,
        selectedItemColor: lightColors.navSelected,
        unselectedItemColor: lightColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColors.primary,
        foregroundColor: lightColors.textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
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
        scrolledUnderElevation: 1,
        shadowColor: darkColors.shadow,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkColors.border.withOpacity(0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors.primary,
          foregroundColor: darkColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.inputFocusBorder, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
          color: darkColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: darkColors.textTertiary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors.navBackground,
        selectedItemColor: darkColors.navSelected,
        unselectedItemColor: darkColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColors.primary,
        foregroundColor: darkColors.textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
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
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textTertiary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textTertiary,
      ),
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
