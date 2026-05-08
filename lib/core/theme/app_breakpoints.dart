import 'package:flutter/widgets.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 768;
  static const double tablet = 1100;
  static const double desktop = 1100;
  static const double wide = 1440;
}

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      width(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final value = width(context);
    return value >= AppBreakpoints.mobile && value <= AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      width(context) > AppBreakpoints.desktop;

  static bool isWide(BuildContext context) =>
      width(context) > AppBreakpoints.wide;
}
