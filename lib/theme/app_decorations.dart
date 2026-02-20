import 'package:flutter/material.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

/// Common decorations and styles for KisanBazaar
class AppDecorations {
  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusRound = BorderRadius.all(Radius.circular(100));
  
  // Shadows
  static const BoxShadow shadowSmall = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow shadowMedium = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow shadowLarge = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  
  // Card Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusMedium,
    boxShadow: const [shadowSmall],
  );
  
  static BoxDecoration cardDecorationElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusMedium,
    boxShadow: const [shadowMedium],
  );
  
  static BoxDecoration cardDecorationHighlight = BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusMedium,
    boxShadow: const [shadowLarge],
    border: Border.all(color: AppColors.primary, width: 2),
  );
  
  // Input Decorations
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.primary)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // Button Decorations
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textLight,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
  );
  
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: radiusMedium),
  );
  
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
  
  // Container Decorations
  static BoxDecoration gradientDecoration = const BoxDecoration(
    gradient: AppColors.primaryGradient,
  );
  
  static BoxDecoration gradientDecorationRounded = const BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: radiusMedium,
  );
  
  // Product Card Decoration
  static BoxDecoration productCardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusLarge,
    boxShadow: const [shadowSmall],
    border: Border.all(color: AppColors.divider, width: 1),
  );
  
  // Badge Decoration
  static BoxDecoration badgeDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: radiusSmall,
    );
  }
  
  // Divider
  static const Divider divider = Divider(
    color: AppColors.divider,
    thickness: 1,
    height: 1,
  );
  
  static const VerticalDivider verticalDivider = VerticalDivider(
    color: AppColors.divider,
    thickness: 1,
    width: 1,
  );
}
