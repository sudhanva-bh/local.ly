import 'package:flutter/material.dart';
import 'package:locally/common/theme/app_colors.dart';

class WidgetProperties {
  static final dropShadow = [
    BoxShadow(
      color: AppColors.light.shadow.withAlpha(155),
      spreadRadius: 2,
      blurRadius: 15,
      offset: Offset(0, 6),
    ),
  ];

  static final subtleDropShadow = [
    BoxShadow(
      color: AppColors.light.shadow.withAlpha(100),
      spreadRadius: 0.5,
      blurRadius: 3,
      offset: Offset(0, 3),
    ),
  ];
}
