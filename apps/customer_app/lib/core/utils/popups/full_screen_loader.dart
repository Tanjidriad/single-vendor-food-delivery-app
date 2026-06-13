import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppFullScreenLoader {
  static void openLoadingDialog(BuildContext context, String text, String animation) {
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
    );
  }

  static void stopLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
