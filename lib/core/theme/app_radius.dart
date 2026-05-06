import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double small = 6;
  static const double medium = 8;
  static const double large = 12;
  static const double extraLarge = 16;
  static const double pill = 999;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
