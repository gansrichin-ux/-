import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const cardShadow = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const elevatedShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 28,
      offset: Offset(0, 18),
    ),
  ];

  static const focusBorder = BorderSide(color: AppColors.primary, width: 1.5);
  static const hoverBorder = BorderSide(color: AppColors.primaryHover);
}
