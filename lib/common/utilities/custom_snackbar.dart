import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/theme/app_colors.dart';

/// A utility class to show themed SnackBars for success, error, and info states.
class CustomSnackbar {
  // Prevent instantiation
  CustomSnackbar._();

  /// Shows a customized SnackBar.
  ///
  /// This is the base method used by [success], [error], and [info].
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Hide any snackbar that is currently visible
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: textColor != null
                ? TextStyle(color: textColor)
                : TextStyle(color: context.colors.onSecondary),
          ),
        ),
        backgroundColor: backgroundColor ?? context.colors.secondary,
        duration: duration,
        behavior: SnackBarBehavior.fixed, // Changed from floating
        // Note: 'shape' and 'margin' are not supported by SnackBarBehavior.fixed
      ),
    );
  }

  /// Shows a success-themed SnackBar (green background, white text).
  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.dark.success,
      textColor: context.colors.onPrimary,
    );
  }

  /// Shows an error-themed SnackBar (red background, white text).
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: context.colors.error,
      textColor: context.colors.onPrimary,
    );
  }

  /// Shows an info-themed SnackBar (blue background, white text).
  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.dark.info,
      textColor: context.colors.onPrimary,
    );
  }
}
