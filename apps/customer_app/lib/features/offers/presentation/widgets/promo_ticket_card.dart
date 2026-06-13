import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/popups/loaders.dart';

class PromoTicketCard extends StatelessWidget {
  const PromoTicketCard({
    super.key,
    required this.coupon,
    required this.isDark,
    this.actionText = 'COPY',
    this.onActionTap,
  });

  final Map<String, dynamic> coupon;
  final bool isDark;
  final String actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final code = coupon['code'] as String;
    final discountType = coupon['discountType'] as String;
    final discountValue = (coupon['discountValue'] as num).toDouble();
    final minOrder = (coupon['minOrderAmount'] as num?)?.toDouble();
    final description = coupon['description'] as String?;

    final discountLabel = discountType == 'PERCENT'
        ? '${discountValue.toInt()}% off'
        : '৳${discountValue.toStringAsFixed(0)} off';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.black400 : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.5),
          style: BorderStyle.solid,
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          // Left portion (Details)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        discountLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (description != null && description.isNotEmpty) ...[
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.white700 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (minOrder != null && minOrder > 0)
                    Text(
                      'Min. order ৳${minOrder.toStringAsFixed(0)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Dashed Divider
          Container(
            width: 1,
            height: 80,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),

          // Right portion (Code & Action)
          InkWell(
            onTap: onActionTap ??
                () {
                  Clipboard.setData(ClipboardData(text: code));
                  AppLoaders.customToast(context, message: 'Coupon code copied to clipboard!');
                },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppSpacing.radiusLg),
              bottomRight: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
