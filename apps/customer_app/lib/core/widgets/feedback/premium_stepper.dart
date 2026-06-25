import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PremiumStepper extends StatelessWidget {
  const PremiumStepper({super.key, required this.currentStep});
  
  final int currentStep; // 1 = Menu, 2 = Cart, 3 = Checkout

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep(context, 'Menu', Icons.restaurant_menu, 1),
          _buildLine(currentStep >= 2),
          _buildStep(context, 'Cart', Icons.shopping_cart, 2),
          _buildLine(currentStep >= 3),
          _buildStep(context, 'Checkout', Icons.payment, 3),
        ],
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 17), // centered with 36px circle
        height: 2,
        color: active ? AppColors.primary : const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String label, IconData icon, int step) {
    final active = currentStep >= step;
    final isCurrent = currentStep == step;
    final isCompleted = currentStep > step;
    
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: const Color(0xFFE5E7EB), width: 2),
              boxShadow: isCurrent ? [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
              ] : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: active ? Colors.white : const Color(0xFF9CA3AF),
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
