import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

class KdsHeader extends ConsumerWidget {
  final bool isConnected;
  final bool isRestaurantActive;
  final ValueChanged<bool> onToggleOnlineStatus;

  const KdsHeader({
    super.key,
    required this.isConnected,
    required this.isRestaurantActive,
    required this.onToggleOnlineStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white50,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Burger Palace',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black500),
              ),
              Row(
                children: [
                  Text(
                    isRestaurantActive ? 'Taking Orders' : 'Paused',
                    style: TextStyle(
                      color: isRestaurantActive ? AppColors.success : AppColors.gray600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    value: isRestaurantActive,
                    activeColor: AppColors.success,
                    onChanged: onToggleOnlineStatus,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    DateFormat.jm().format(DateTime.now()),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.successLight : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: isConnected ? AppColors.success : AppColors.error, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Network: OK' : 'Network: Offline',
                      style: TextStyle(color: isConnected ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
