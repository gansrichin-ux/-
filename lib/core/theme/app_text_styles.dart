import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 40,
    height: 1.08,
    letterSpacing: 0,
    fontWeight: FontWeight.w800,
  );

  static const titleLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    height: 1.14,
    letterSpacing: 0,
    fontWeight: FontWeight.w800,
  );

  static const titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    height: 1.25,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  static const titleSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.3,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  static const bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.45,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.4,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    height: 1.35,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.25,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  static const button = TextStyle(
    fontSize: 14,
    height: 1.2,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );
}
