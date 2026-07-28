import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
  static const emphasized = Duration(milliseconds: 360);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubicEmphasized;
}

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const expanded = 1024.0;
  static const customerContentMaxWidth = 760.0;
  static const dashboardContentMaxWidth = 1440.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F17324D), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const floating = [
    BoxShadow(color: Color(0x24152F47), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
