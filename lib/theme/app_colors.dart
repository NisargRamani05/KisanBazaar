import 'package:flutter/material.dart';

/// App Color Palette for KisanBazaar
/// Agricultural/Nature-inspired green theme
class AppColors {
  // Primary Colors - Green shades for agricultural theme
  static const Color primary = Color(0xFF2E7D32); // Deep Green
  static const Color primaryLight = Color(0xFF60AD5E); // Light Green
  static const Color primaryDark = Color(0xFF005005); // Dark Green
  
  // Secondary Colors - Earthy tones
  static const Color secondary = Color(0xFF8D6E63); // Warm Brown
  static const Color secondaryLight = Color(0xFFBE9C91);
  static const Color secondaryDark = Color(0xFF5D4037);
  
  // Accent Colors
  static const Color accent = Color(0xFF66BB6A); // Fresh Leaf Green
  static const Color accentLight = Color(0xFF98EE99);
  static const Color accentDark = Color(0xFF338A3E);
  
  // Background Colors
  static const Color background = Color(0xFFF9F6EF); // Soft Cream
  static const Color backgroundDark = Color(0xFF121212); // Dark mode
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Almost Black
  static const Color textSecondary = Color(0xFF757575); // Gray
  static const Color textLight = Color(0xFFFFFFFF); // White
  static const Color textHint = Color(0xFFBDBDBD); // Light Gray
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color warning = Color(0xFFFFA726); // Orange
  static const Color info = Color(0xFF29B6F6); // Blue
  
  // Functional Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x80000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
