import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double screenHorizontalPadding = 16;
  static const double screenVerticalPadding = 16;
  static const double screenBottomPadding = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets screenPaddingNoTop = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets sectionPadding = EdgeInsets.only(bottom: 16);
  static const EdgeInsets bottomNavPadding = EdgeInsets.fromLTRB(16, 0, 16, 16);

  static const double cardRadius = 20;
  static const double controlRadius = 16;
  static const double inputHeight = 52;
  static const double buttonHeight = 48;
  static const double iconBox = 44;
}
