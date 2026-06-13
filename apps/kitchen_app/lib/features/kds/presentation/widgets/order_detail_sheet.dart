import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';
import 'order_channel_badge.dart';
import 'order_notes_highlight.dart';
import 'order_timer.dart';

/// Expanded detail sheet for a kitchen order.
///
/// Shows full item list, modifiers, customer notes, reject reason, rider ETA,
/// and a manual print button. Used when a tile is tapped in the KDS.
class OrderDetailSheet extends ConsumerWidget {
  final dynamic order;
  final String? nextStatus;
  final String actionText;
  final VoidCallback onAction;
  final VoidCallback? onReject;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final Color accentColor;

  const OrderDetailSheet({
    super.key,
    required this.order,
    required this.nextStatus,
    required this.actionText,
    required this.onAction,
    this.onReject,
    this.onSecondaryAction,
    this.secondaryActionText,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderMap = order as Map<String, dynamic>;
    final items = (orderMap['items'] as List<dynamic>?) ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle.
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  '#${orderMap['orderNumber']?.toString() ?? '---'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                OrderChannelBadge(order: orderMap),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.printer, color: AppColors.gray700),
                  tooltip: 'Print kitchen ticket',
                  onPressed: () => _printTicket(context, ref, orderMap),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: AppColors.gray700),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),

          // Scrollable content.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(orderMap),
                  const SizedBox(height: 16),
                  _buildCustomerCard(orderMap),
                  const SizedBox(height: 16),
                  OrderNotesHighlight(
                    deliveryNote: orderMap['deliveryNote']?.toString(),
                    itemNotes: OrderNotesHighlight.extractItemNotes(items),
                  ),
                  const SizedBox(height: 8),
                  _buildItemsList(items),
                  const SizedBox(height: 16),
                  _buildStatusNotes(orderMap),
                  const SizedBox(height: 16),
                  _buildRiderInfo(orderMap),
                  if (secondaryActionText != null && onSecondaryAction != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray800,
                          side: const BorderSide(color: AppColors.gray300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onSecondaryAction,
                        icon: const Icon(Iconsax.truck_fast, size: 18),
                        label: Text(
                          secondaryActionText!,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  // Bottom padding for action bar.
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky action bar.
          _buildActionBar(context),
        ],
      ),
    );
  }

  Widget _buildMetaRow(Map<String, dynamic> orderMap) {
    final canonical = OrderWorkflowMapper.getCanonicalStatus(orderMap);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    final anchor = OrderWorkflowMapper.getTimerAnchor(orderMap, timerType);
    final prefix = OrderWorkflowMapper.getTimerLabelPrefix(timerType);
    final slaSeconds = switch (timerType) {
      TimerType.acceptance => orderMap['slaAcceptSeconds'] as int? ?? 300,
      TimerType.preparation => orderMap['slaPrepSeconds'] as int? ?? 1200,
      TimerType.pickupWait => orderMap['slaPickupWaitSeconds'] as int? ?? 900,
      _ => 0,
    };

    return Row(
      children: [
        Expanded(
          child: _MetaItem(
            icon: Iconsax.clock,
            label: 'Placed',
            value: _formatTime(orderMap['placedAt'] ?? orderMap['createdAt']),
          ),
        ),
        Expanded(
          child: _MetaItem(
            icon: Iconsax.money,
            label: 'Payment',
            value: _paymentLabel(orderMap),
          ),
        ),
        if (timerType != TimerType.none && anchor != null)
          Expanded(
            child: OrderStageTimer(
              timerType: timerType,
              startTime: anchor,
              labelPrefix: prefix,
              slaThresholdSeconds: slaSeconds,
              compact: false,
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> orderMap) {
    final name = orderMap['customerName']?.toString() ?? 'Guest';
    final phone = orderMap['customerPhone']?.toString();
    final address = orderMap['deliveryAddress']?.toString();
    final orderType = orderMap['orderType']?.toString().toUpperCase();
    final isPickup = orderType == 'PICKUP';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.user, size: 16, color: AppColors.gray700),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Iconsax.call, size: 16, color: AppColors.gray700),
                const SizedBox(width: 8),
                Text(phone, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (!isPickup && address != null && address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.location, size: 16, color: AppColors.gray700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ORDER ITEMS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.gray700),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final item = entry.value as Map<String, dynamic>;
          final addons = (item['addons'] as List<dynamic>?) ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item['quantity'] ?? 1}x',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'Item',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (addons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: addons.map((addon) {
                              return Text(
                                '+ ${addon['name']}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              );
                            }).toList(),
                          ),
                        ),
                      if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Iconsax.info_circle, size: 14, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item['notes'].toString(),
                                    style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusNotes(Map<String, dynamic> orderMap) {
    final status = orderMap['status']?.toString();
    final cancelledReason = orderMap['cancelledReason']?.toString();
    final history = (orderMap['statusHistory'] as List<dynamic>?) ?? [];
    final rejectNote = history
        .where((h) => h['status']?.toString() == 'REJECTED')
        .map((h) => h['note']?.toString())
        .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null);

    final note = cancelledReason ?? rejectNote;
    if (status != 'REJECTED' && status != 'CANCELLED') return const SizedBox.shrink();
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.note_text, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                status == 'REJECTED' ? 'REJECT REASON' : 'CANCEL REASON',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInfo(Map<String, dynamic> orderMap) {
    final assignment = orderMap['assignment'];
    String? riderName;
    if (assignment is Map) {
      final rider = assignment['rider'];
      if (rider is Map) {
        riderName = rider['fullName']?.toString();
      }
    }
    final eta = orderMap['routeEtaMinutes'] as int?;
    final deliveryService = orderMap['deliveryService']?.toString();
    final trackingId = orderMap['trackingId']?.toString();

    if (riderName == null && eta == null && deliveryService == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.truck_fast, size: 16, color: AppColors.pandaPink),
              SizedBox(width: 8),
              Text(
                'RIDER / DELIVERY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.pandaPink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (riderName != null)
            Text('Rider: $riderName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (eta != null)
            Text('ETA: $eta min', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          if (deliveryService != null)
            Text('Service: $deliveryService', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          if (trackingId != null)
            Text('Tracking: $trackingId', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final showReject = onReject != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white50,
        border: const Border(top: BorderSide(color: AppColors.gray200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showReject) ...[
              Expanded(
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
              flex: showReject ? 2 : 1,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.white50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
                  },
                  child: Text(
                    actionText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(Map<String, dynamic> orderMap) {
    final method = orderMap['paymentMethod']?.toString();
    final status = orderMap['paymentStatus']?.toString();
    if (method == 'ONLINE' && status == 'PAID') return 'Prepaid';
    if (method == 'ONLINE') return 'Unpaid';
    if (method == 'WALLET') return 'Wallet';
    return 'COD';
  }

  String _formatTime(dynamic value) {
    if (value == null) return 'N/A';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    return DateFormat.jm().format(dt);
  }

  Future<void> _printTicket(BuildContext context, WidgetRef ref, Map<String, dynamic> orderMap) async {
    try {
      await ref.read(printServiceProvider).printKitchenTicket(orderMap);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitchen ticket printed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.gray700),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
