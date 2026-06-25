import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppFullScreenLoader {
  /// Tracks whether the loader dialog is currently shown, so [stopLoading]
  /// never pops a real page when the dialog isn't open (which crashes GoRouter
  /// with "popped the last page off of the stack").
  static bool _isOpen = false;

  static void openLoadingDialog(BuildContext context, String text, String animation) {
    if (_isOpen) return;
    _isOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(animation, width: MediaQuery.of(context).size.width * 0.8),
                const SizedBox(height: 24),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => _isOpen = false);
  }

  static void stopLoading(BuildContext context) {
    if (!_isOpen) return;
    _isOpen = false;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
  }
}
