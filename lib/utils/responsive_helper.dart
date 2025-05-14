import 'package:flutter/material.dart';

/// Helper class to manage responsive design across the app
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1100;
  static const double desktopBreakpoint = 1200;

  /// Returns true if the screen width is considered mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Returns true if the screen width is considered tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Returns true if the screen width is considered desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Returns true if the screen is a larger device (tablet or desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  /// Returns an appropriate width constraint for content containers
  /// that should be limited in width on larger screens
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > desktopBreakpoint) {
      // On very large screens, limit the content width
      return desktopBreakpoint - 200;
    } else if (width > tabletBreakpoint) {
      // On desktop, limit the content width with side margins
      return width - 100;
    } else if (width > mobileBreakpoint) {
      // On tablet, allow slightly more space
      return width - 60;
    } else {
      // On mobile, use nearly full width
      return width - 32;
    }
  }

  /// Returns the number of grid columns to use based on screen width
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1400) {
      return 5; // Large desktop
    } else if (width > desktopBreakpoint) {
      return 4; // Desktop
    } else if (width > tabletBreakpoint) {
      return 3; // Small desktop / large tablet
    } else if (width > mobileBreakpoint) {
      return 2; // Tablet
    } else {
      return 2; // Mobile (2 columns still works well on most mobile devices)
    }
  }

  /// Returns appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(24.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(8.0);
    }
  }

  /// Returns appropriate side padding for the main content area
  static EdgeInsets getContentPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
    }
  }

  /// Returns the grid item height based on screen size
  static double getGridItemHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 280; // Taller items on desktop
    } else if (isTablet(context)) {
      return 260; // Slightly taller on tablet
    } else {
      return 240; // Standard height on mobile
    }
  }

  /// Returns a child aspect ratio for grid items based on screen size
  static double getGridItemAspectRatio(BuildContext context) {
    if (isDesktop(context)) {
      return 0.85; // More square-like on desktop
    } else if (isTablet(context)) {
      return 0.8; // Slightly taller on tablet
    } else {
      return 0.75; // Taller than wide on mobile
    }
  }
}