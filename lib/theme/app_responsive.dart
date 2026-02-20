import 'package:flutter/material.dart';

/// Responsive utilities for KisanBazaar
/// Handles different screen sizes and orientations
class AppResponsive {
  /// Screen breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  static const double desktopMaxWidth = 1200;
  
  /// Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }
  
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get percentage of screen width
  static double widthPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.width * (percent / 100);
  }
  
  /// Get percentage of screen height
  static double heightPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.height * (percent / 100);
  }
  
  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Responsive value based on screen size
  /// Returns different values for mobile, tablet, and desktop
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
  
  /// Responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < mobileMaxWidth) {
      return baseSize;
    } else if (width < tabletMaxWidth) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }
  
  /// Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }
  
  /// Grid column count based on screen size
  static int gridColumnCount(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }
  
  /// Maximum content width for large screens
  static double maxContentWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );
  }
  
  /// Orientation check
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}

/// Responsive spacing utilities
class AppSpacing {
  /// Extra small spacing (4px)
  static const double xs = 4.0;
  
  /// Small spacing (8px)
  static const double sm = 8.0;
  
  /// Medium spacing (16px)
  static const double md = 16.0;
  
  /// Large spacing (24px)
  static const double lg = 24.0;
  
  /// Extra large spacing (32px)
  static const double xl = 32.0;
  
  /// Extra extra large spacing (48px)
  static const double xxl = 48.0;
  
  /// Responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: AppResponsive.responsiveValue(
        context,
        mobile: md,
        tablet: lg,
        desktop: xl,
      ),
    );
  }
  
  /// Responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      vertical: AppResponsive.responsiveValue(
        context,
        mobile: md,
        tablet: lg,
        desktop: xl,
      ),
    );
  }
  
  /// Responsive all-around padding
  static EdgeInsets allPadding(BuildContext context) {
    return EdgeInsets.all(
      AppResponsive.responsiveValue(
        context,
        mobile: md,
        tablet: lg,
        desktop: xl,
      ),
    );
  }
}

/// Responsive layout builder widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppResponsive.tabletMaxWidth) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppResponsive.mobileMaxWidth) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
  });
  
  @override
  Widget build(BuildContext context) {
    final columnCount = AppResponsive.responsiveValue(
      context,
      mobile: mobileColumns ?? 2,
      tablet: tabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
    );
    
    return GridView.count(
      crossAxisCount: columnCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      children: children,
    );
  }
}

/// Centered content container with max width
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppResponsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

/// Responsive container with percentage width/height
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? widthPercent;
  final double? heightPercent;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.widthPercent,
    this.heightPercent,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widthPercent != null
          ? AppResponsive.widthPercent(context, widthPercent!)
          : null,
      height: heightPercent != null
          ? AppResponsive.heightPercent(context, heightPercent!)
          : null,
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? widthPercent;
  final double? heightPercent;
  final Widget? child;
  
  const ResponsiveSizedBox({
    super.key,
    this.widthPercent,
    this.heightPercent,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widthPercent != null
          ? AppResponsive.widthPercent(context, widthPercent!)
          : null,
      height: heightPercent != null
          ? AppResponsive.heightPercent(context, heightPercent!)
          : null,
      child: child,
    );
  }
}
