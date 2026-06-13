import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';

class KdsHeader extends ConsumerWidget {
  final bool isConnected;
  final bool isRestaurantActive;
  final ValueChanged<bool> onToggleOnlineStatus;
  final VoidCallback? onMenuPressed;

  const KdsHeader({
    super.key,
    required this.isConnected,
    required this.isRestaurantActive,
    required this.onToggleOnlineStatus,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);
    final displayName = restaurantAsync.when(
      data: (s) => s.displayName,
      loading: () => 'Kitchen',
      error: (error, stackTrace) => 'Kitchen',
    );
    final user = ref.watch(authProvider).user;
    final staffName = user?['fullName']?.toString();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onMenuPressed != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                    onPressed: onMenuPressed,
                    tooltip: 'Open navigation',
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  if (staffName != null && staffName.isNotEmpty)
                    Text(
                      'Staff: $staffName',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.gray700),
                    ),
                ],
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
                  Semantics(
                    label: isRestaurantActive ? 'Pause taking orders' : 'Start taking orders',
                    button: true,
                    child: CupertinoSwitch(
                      value: isRestaurantActive,
                      activeTrackColor: AppColors.success,
                      onChanged: onToggleOnlineStatus,
                    ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.gray800),
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
