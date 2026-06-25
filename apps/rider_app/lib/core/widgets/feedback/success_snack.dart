import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Green confirmation snackbar for successful actions.
class SuccessSnack {
  SuccessSnack._();

  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.online,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
