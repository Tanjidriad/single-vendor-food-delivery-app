import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NewOrderAlertOverlay extends StatelessWidget {
  final int count;
  final VoidCallback onDismiss;

  const NewOrderAlertOverlay({
    super.key,
    required this.count,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.white50,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'You have $count new\npending order${count == 1 ? '!' : 's!'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white50,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start accepting orders.',
                style: TextStyle(
                  color: AppColors.white50,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Tap anywhere to view',
                style: TextStyle(
                  color: AppColors.white50,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
