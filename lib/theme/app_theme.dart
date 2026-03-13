import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/theme/app_text_styles.dart';

/// Main theme configuration for KisanBazaar
class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.textPrimary,
      
      secondary: AppColors.secondary,
      onSecondary: AppColors.textLight,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.textPrimary,
      
      tertiary: AppColors.accent,
      onTertiary: AppColors.textPrimary,
      
      error: AppColors.error,
      onError: AppColors.textLight,
      
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
      
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      
      surfaceVariant: AppColors.background,
      onSurfaceVariant: AppColors.textSecondary,
      
      outline: AppColors.divider,
      shadow: AppColors.shadow,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.background,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(textStyle: AppTextStyles.bodyMedium),
      hintStyle: GoogleFonts.inter(textStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
      errorStyle: GoogleFonts.inter(textStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.primary,
      size: 24,
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 4,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(textStyle: AppTextStyles.labelMedium),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Text Theme
    textTheme: GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    )),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.textLight,
      
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.textLight,
      
      tertiary: AppColors.accentLight,
      onTertiary: AppColors.textPrimary,
      
      error: AppColors.error,
      onError: AppColors.textLight,
      
      background: AppColors.backgroundDark,
      onBackground: AppColors.textLight,
      
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textLight,
      
      surfaceVariant: AppColors.backgroundDark,
      onSurfaceVariant: AppColors.textSecondary,
      
      outline: AppColors.divider,
      shadow: AppColors.shadow,
    ),
    
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Text Theme (Added for darker mode too)
    textTheme: GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    )).apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),
  );
}
