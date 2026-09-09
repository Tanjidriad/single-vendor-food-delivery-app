import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';

class NewOrderSquareCard extends StatefulWidget {
  final dynamic order;
  final VoidCallback onTap;

  const NewOrderSquareCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  State<NewOrderSquareCard> createState() => _NewOrderSquareCardState();
}

class _NewOrderSquareCardState extends State<NewOrderSquareCard> {
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
  void didUpdateWidget(NewOrderSquareCard oldWidget) {
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
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#$orderNumber',
              style: const TextStyle(
                color: AppColors.white50,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$totalQuantity item${totalQuantity == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.white50,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _timerText,
              style: const TextStyle(
                color: AppColors.white50,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
