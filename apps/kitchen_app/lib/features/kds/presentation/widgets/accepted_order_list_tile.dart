import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';
import 'dispatch_status_chip.dart';

class AcceptedOrderListTile extends StatefulWidget {
  final dynamic order;
  final VoidCallback onTap;

  const AcceptedOrderListTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  State<AcceptedOrderListTile> createState() => _AcceptedOrderListTileState();
}

class _AcceptedOrderListTileState extends State<AcceptedOrderListTile> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  @override
  void didUpdateWidget(AcceptedOrderListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateElapsed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final anchor = _timerAnchor;
    if (anchor == null) return;
    setState(() {
      _elapsed = DateTime.now().difference(anchor);
    });
  }

  DateTime? get _timerAnchor {
    final order = widget.order as Map<String, dynamic>;
    final canonical = OrderWorkflowMapper.getCanonicalStatus(order);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    return OrderWorkflowMapper.getTimerAnchor(order, timerType);
  }

  String get _timerText {
    final minutes = _elapsed.inMinutes;
    return '$minutes min${minutes == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order as Map<String, dynamic>;
    final orderNumber = order['orderNumber']?.toString() ?? '---';
    final shortCode = order['shortCode']?.toString() ?? '';
    final paymentMethod = order['paymentMethod']?.toString() ?? 'PAID';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white50,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colored bar based on status
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _getLeftBarColor(order['status']?.toString()),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#$orderNumber',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLeftBarColor(
                                    order['status']?.toString(),
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusText(order['status']?.toString()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _getLeftBarColor(
                                      order['status']?.toString(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            paymentMethod.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shortCode.isNotEmpty ? '$shortCode - ' : ''}$totalQuantity item${totalQuantity == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DispatchStatusChip(order: order),
                          ),
                          Text(
                            _timerText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLeftBarColor(String? status) {
    if (status == 'PREPARING') return AppColors.warning;
    if (status == 'READY_FOR_PICKUP') return AppColors.success;
    return AppColors.gray400; // default for ACCEPTED
  }

  String _getStatusText(String? status) {
    if (status == 'PREPARING') return 'PREPARING';
    if (status == 'READY_FOR_PICKUP') return 'READY';
    return 'ACCEPTED';
  }
}
