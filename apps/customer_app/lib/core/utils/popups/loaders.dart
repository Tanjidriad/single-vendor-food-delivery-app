import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/app_colors.dart';
import '../helpers/helper_functions.dart';

class AppLoaders {
  AppLoaders._();

  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void customToast(BuildContext context, {required String message}) {
    final isDark = AppHelperFunctions.isDarkMode(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: isDark
            ? AppColors.black500.withValues(alpha: 0.9)
            : AppColors.textDisabled.withValues(alpha: 0.9),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  static void successSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
    int durationSeconds = 3,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: AppColors.primary,
      icon: Iconsax.check,
      durationSeconds: durationSeconds,
    );
  }

  static void warningSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      icon: Iconsax.warning_2,
    );
  }

  static void errorSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Iconsax.warning_2,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    int durationSeconds = 3,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: Duration(seconds: durationSeconds),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef TLoaders = AppLoaders;
