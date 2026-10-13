// ============================================================
// FILE: lib/src/core/media_layout.dart
// NextGen Media Utility - Layout & Spacing Tokens
// ============================================================

import 'package:flutter/material.dart';

class AppLayout {
  AppLayout._();

  static const double space2xs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;
  static const double space3xl = 48.0;

  static const SizedBox gapXs = SizedBox(width: spaceXs, height: spaceXs);
  static const SizedBox gapSm = SizedBox(width: spaceSm, height: spaceSm);
  static const SizedBox gapMd = SizedBox(width: spaceMd, height: spaceMd);
  static const SizedBox gapLg = SizedBox(width: spaceLg, height: spaceLg);
  static const SizedBox gapXl = SizedBox(width: spaceXl, height: spaceXl);
  static const SizedBox gap2xl = SizedBox(width: space2xl, height: space2xl);

  static const double compactWidth = 360.0;
  static const double standardWidth = 412.0;
  static const double tabletWidth = 600.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < AppLayout.compactWidth;
  bool get isTablet => screenWidth >= AppLayout.tabletWidth;

  T responsive<T>({
    required T standard,
    T? compact,
    T? tablet,
  }) {
    if (isTablet && tablet != null) return tablet;
    if (isCompact && compact != null) return compact;
    return standard;
  }

  EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: responsive(standard: 16.0, compact: 12.0, tablet: 24.0),
    vertical: 16.0,
  );
}
