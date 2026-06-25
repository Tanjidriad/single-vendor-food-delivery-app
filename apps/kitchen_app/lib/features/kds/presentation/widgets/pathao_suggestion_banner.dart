import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kds_provider.dart';

class PathaoSuggestionBanner extends StatelessWidget {
  final List<DispatchAlert> alerts;
  final void Function(String orderId) onSendToPathao;
  final void Function(String orderId) onRetryAssign;
  final void Function(String orderId) onDismiss;

  const PathaoSuggestionBanner({
    super.key,
    required this.alerts,
    required this.onSendToPathao,
    required this.onRetryAssign,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: alerts.map((alert) => _buildBanner(context, alert)).toList(),
    );
  }

  Widget _buildBanner(BuildContext context, DispatchAlert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No riders for #${alert.orderNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All riders exhausted. Send via Pathao or retry.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSendToPathao(alert.orderId);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: const Text('Pathao'),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetryAssign(alert.orderId);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray400),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Retry'),
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              onPressed: () => onDismiss(alert.orderId),
              icon: Icon(
                Icons.close,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
