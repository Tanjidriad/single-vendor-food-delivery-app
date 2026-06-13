import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

const _backendSteps = [
  'PLACED',
  'ACCEPTED',
  'PREPARING',
  'READY_FOR_PICKUP',
  'PICKED_UP',
  'ON_THE_WAY',
  'DELIVERED',
];

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.currentStatus});

  final String currentStatus;

  int get _currentIndex {
    final idx = _backendSteps.indexOf(currentStatus.toUpperCase());
    return idx < 0 ? 0 : idx;
  }

  // Map backend steps to 4 visual milestones
  int get _visualStep {
    if (_currentIndex <= 1) return 0; // Placed, Accepted -> Confirmed
    if (_currentIndex <= 3) return 1; // Preparing, Ready -> Preparing
    if (_currentIndex <= 5) return 2; // Picked up, On the way -> On the way
    return 3; // Delivered
  }

  @override
  Widget build(BuildContext context) {
    final visualStep = _visualStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Bar
        Stack(
          children: [
            // Background track
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Animated active track
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 6,
              width: MediaQuery.of(context).size.width * ((visualStep + 1) / 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepLabel('Confirmed', isActive: visualStep >= 0),
            _buildStepLabel('Preparing', isActive: visualStep >= 1),
            _buildStepLabel('On the way', isActive: visualStep >= 2),
            _buildStepLabel('Delivered', isActive: visualStep >= 3),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLabel(String label, {required bool isActive}) {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
