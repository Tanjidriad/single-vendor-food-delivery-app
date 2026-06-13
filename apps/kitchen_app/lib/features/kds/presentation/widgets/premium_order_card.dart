import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import 'order_notes_highlight.dart';
import 'order_timer.dart';
import '../../domain/order_workflow.dart';

class PremiumOrderCard extends StatelessWidget {
  final dynamic order;
  final String? nextStatus;
  final String actionText;
  final VoidCallback onAction;
  final VoidCallback? onReject;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final Color accentColor;

  const PremiumOrderCard({
    super.key,
    required this.order,
    required this.nextStatus,
    required this.actionText,
    required this.onAction,
    this.onReject,
    this.secondaryActionText,
    this.onSecondaryAction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final orderTime = order['createdAt'] != null ? DateFormat.jm().format(DateTime.parse(order['createdAt'])) : 'N/A';
    final itemsList = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${order['orderNumber'] ?? '---'}',
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          orderTime,
                          style: const TextStyle(color: AppColors.gray800, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _PaymentBadge(order: order),
                const SizedBox(width: 8),
                Icon(Iconsax.receipt, color: AppColors.gray500, size: 20),
                const SizedBox(width: 8),
                Builder(builder: (context) {
                  final orderMap = order as Map<String, dynamic>;
                  final canonical = OrderWorkflowMapper.getCanonicalStatus(
                    orderMap,
                    includeTestOrders: true,
                  );
                  final timerType = OrderWorkflowMapper.getTimerType(canonical);
                  if (timerType == TimerType.none) return const SizedBox.shrink();

                  final anchor = OrderWorkflowMapper.getTimerAnchor(orderMap, timerType);
                  final prefix = OrderWorkflowMapper.getTimerLabelPrefix(timerType);
                  
                  int slaSeconds = 1200; // default prep 20m
                  if (timerType == TimerType.acceptance) slaSeconds = 300; // 5m
                  if (timerType == TimerType.pickupWait) slaSeconds = 900; // 15m

                  return OrderStageTimer(
                    timerType: timerType,
                    startTime: anchor,
                    labelPrefix: prefix,
                    slaThresholdSeconds: slaSeconds,
                    compact: true,
                  );
                }),
              ],
            ),
          ),
          
          // Special instructions / delivery notes (prominent red highlight)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OrderNotesHighlight(
              deliveryNote: order['deliveryNote']?.toString(),
              itemNotes: OrderNotesHighlight.extractItemNotes(
                order['items'] as List<dynamic>?,
              ),
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: itemsList.isNotEmpty 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itemsList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Text(
                            '${item['quantity'] ?? 1}x', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black500),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'Item',
                                style: const TextStyle(color: AppColors.black500, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              if (item['addons'] != null && (item['addons'] as List).isNotEmpty)
                                ...((item['addons'] as List).map((addon) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('+ ${addon['name']}', style: const TextStyle(color: AppColors.gray700, fontSize: 13)),
                                ))),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Iconsax.info_circle, size: 14, color: AppColors.warning),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item['notes'],
                                          style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                )
              : Text(
                  order['itemsSummary'] ?? 'No items provided',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.black500),
                ),
          ),
          
          if (secondaryActionText != null && onSecondaryAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray800,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onSecondaryAction,
                  child: Text(
                    secondaryActionText!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Action Button
          if (nextStatus != null)
            Padding(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              child: Row(
                children: [
                  if (onReject != null) ...[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: onReject,
                          child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: onReject != null ? 2 : 1,
                    child: SizedBox(
                      height: 52, // Large touch target for Sunmi
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pandaPink,
                          foregroundColor: AppColors.white50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onAction,
                        child: Text(actionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.order});

  final dynamic order;

  @override
  Widget build(BuildContext context) {
    final method = order['paymentMethod']?.toString() ?? 'COD';
    final status = order['paymentStatus']?.toString() ?? 'PENDING';

    late final String label;
    late final Color color;

    if (method == 'ONLINE' && status == 'PAID') {
      label = 'Prepaid';
      color = AppColors.success;
    } else if (method == 'ONLINE') {
      label = 'Unpaid';
      color = AppColors.warning;
    } else {
      label = 'COD';
      color = AppColors.gray700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
