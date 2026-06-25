import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/print_preview_overlay.dart';
import '../providers/kds_provider.dart';
import '../../domain/order_workflow.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final anchor = _timerAnchor;
    if (anchor == null) return;
    setState(() => _elapsed = DateTime.now().difference(anchor));
  }

  DateTime? get _timerAnchor {
    final canonical = OrderWorkflowMapper.getCanonicalStatus(widget.order);
    final timerType = OrderWorkflowMapper.getTimerType(canonical);
    return OrderWorkflowMapper.getTimerAnchor(widget.order, timerType);
  }

  String get _timerText {
    final minutes = _elapsed.inMinutes;
    return '$minutes min${minutes == 1 ? '' : 's'}';
  }

  // ---- Display helpers ----------------------------------------------------

  /// Clean daily serial like "#042". Falls back to the last 4 of the FD code
  /// for older orders created before daily serials existed.
  String get _serialDisplay {
    final serial = widget.order['dailySerial'];
    if (serial is int) return '#${serial.toString().padLeft(3, '0')}';
    final num = widget.order['orderNumber']?.toString() ?? '';
    return num.length > 4 ? '#${num.substring(num.length - 4)}' : '#$num';
  }

  String get _serialSubtitle {
    final serial = widget.order['dailySerial'];
    final placed = widget.order['placedAt'] ?? widget.order['createdAt'];
    final dt = placed != null ? DateTime.tryParse(placed.toString()) : null;
    final dateStr = dt != null ? DateFormat('d MMM').format(dt.toLocal()) : '';
    if (serial is int) {
      final ord = _ordinal(serial);
      return '$ord order today${dateStr.isNotEmpty ? ' · $dateStr' : ''}';
    }
    return dateStr;
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String get _statusLabel {
    switch (widget.order['status']) {
      case 'PLACED':
        return 'New order';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PREPARING':
        return 'Preparing';
      case 'READY_FOR_PICKUP':
        return 'Ready for pickup';
      case 'PICKED_UP':
        return 'Picked up';
      case 'ON_THE_WAY':
        return 'Delivery in progress';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REJECTED':
        return 'Rejected';
      case 'DELIVERY_FAILED':
        return 'Delivery failed';
      case 'RETURNED_TO_RESTAURANT':
        return 'Returned';
      default:
        return widget.order['status']?.toString() ?? '';
    }
  }

  String _money(num? value) => '৳${(value ?? 0).toStringAsFixed(2)}';

  Future<void> _printTicket(BuildContext context) async {
    try {
      await ref.read(printServiceProvider).printKitchenTicket(widget.order);
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

  void _updateStatus(String nextStatus) {
    ref.read(kdsProvider.notifier).updateOrderStatus(widget.order['id'], nextStatus);
    Navigator.of(context).pop();
  }

  Future<void> _showPathaoDialog(BuildContext context, String orderId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Send to Pathao'),
          ],
        ),
        content: const Text(
          'Pathao will automatically create a parcel and assign a tracking ID. '
          'The customer will be notified with a live tracking link.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Confirm & Send'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    navigator.pop();

    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Creating Pathao parcel…'),
          ],
        ),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref.read(kdsProvider.notifier).dispatchToPathao(orderId, trackingId: '');
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ Order dispatched via Pathao — tracking ID assigned'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not dispatch to Pathao: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order['items'] as List<dynamic>?) ?? [];

    String? nextStatus;
    String? actionText;
    Color buttonColor = AppColors.success;

    final assignmentStatus =
        order['assignment'] is Map ? order['assignment']['status']?.toString() : null;
    final canSendPathao = order['status'] == 'READY_FOR_PICKUP' &&
        order['deliveryService'] == null &&
        (assignmentStatus == null ||
            assignmentStatus == 'EXPIRED' ||
            assignmentStatus == 'REJECTED' ||
            assignmentStatus == 'CANCELLED');

    switch (order['status']) {
      case 'PLACED':
        nextStatus = 'ACCEPTED';
        actionText = 'Accept order';
        break;
      case 'ACCEPTED':
        nextStatus = 'PREPARING';
        actionText = 'Start preparing';
        buttonColor = AppColors.warning;
        break;
      case 'PREPARING':
        nextStatus = 'READY_FOR_PICKUP';
        actionText = 'Mark ready';
        buttonColor = AppColors.success;
        break;
    }

    return PrintPreviewOverlay(
      child: Scaffold(
        backgroundColor: AppColors.white50,
        appBar: AppBar(
          backgroundColor: AppColors.pandaPink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Order details',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.printer, color: Colors.white),
              tooltip: 'Print kitchen ticket',
              onPressed: () => _printTicket(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildInvoiceButtons(context),
                  _buildHero(),
                  const SizedBox(height: 4),
                  _buildInfoRows(order),
                  _buildItems(items),
                  _buildNote(order),
                  _buildBreakdown(order),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (nextStatus != null || canSendPathao)
              _buildActionBar(context, order, nextStatus, actionText, buttonColor, canSendPathao),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceButtons(BuildContext context) {
    Widget btn(IconData icon, String label) => Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pandaPink,
              backgroundColor: AppColors.pandaPinkLight,
              side: const BorderSide(color: AppColors.pandaPink),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onPressed: () => _printTicket(context),
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          btn(Iconsax.receipt_1, 'Customer inv'),
          const SizedBox(width: 10),
          btn(Iconsax.reserve, 'Kitchen inv'),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        children: [
          Text(
            _serialDisplay,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.black500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _serialSubtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.pandaPinkLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.clock, size: 14, color: AppColors.pandaPink),
                const SizedBox(width: 6),
                Text(
                  '$_statusLabel · $_timerText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pandaPink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.order['orderNumber']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray700,
              letterSpacing: 0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRows(Map<String, dynamic> order) {
    final restaurantName = order['restaurant']?['name']?.toString() ?? 'Restaurant';
    final customerName = order['customerName']?.toString() ?? 'Guest';
    final rider = order['assignment'] is Map ? order['assignment']['rider'] : null;
    final riderName = rider is Map ? rider['fullName']?.toString() : null;

    return Column(
      children: [
        _infoRow(Iconsax.shop, 'Branch', restaurantName),
        _infoRow(Iconsax.user, 'Customer', customerName, trailing: _paymentBadge(order)),
        if (riderName != null)
          _infoRow(Iconsax.truck_fast, 'Rider', riderName)
        else
          _infoRow(Iconsax.truck_fast, 'Rider', 'Not assigned yet', muted: true),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Widget? trailing, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.pandaPink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.pandaPink)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: muted ? AppColors.gray800 : AppColors.black500)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 18, thickness: 0.5, color: AppColors.gray500),
        ],
      ),
    );
  }

  Widget _paymentBadge(Map<String, dynamic> order) {
    final method = order['paymentMethod']?.toString();
    final status = order['paymentStatus']?.toString();
    late String label;
    late Color bg;
    late Color fg;
    if (method == 'ONLINE' && status == 'PAID') {
      label = 'Online paid';
      bg = AppColors.successLight;
      fg = const Color(0xFF065F46);
    } else if (method == 'ONLINE') {
      label = 'Online unpaid';
      bg = AppColors.warningLight;
      fg = const Color(0xFF92400E);
    } else if (method == 'WALLET') {
      label = 'Wallet';
      bg = AppColors.infoLight;
      fg = const Color(0xFF155E75);
    } else {
      label = 'Cash on delivery';
      bg = AppColors.pandaPinkLight;
      fg = AppColors.pandaPinkDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildItems(List<dynamic> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray500, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: items.map((raw) {
          final item = raw as Map<String, dynamic>;
          final qty = item['quantity']?.toString() ?? '1';
          final name = item['name']?.toString() ?? 'Item';
          final price = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
          final addons = (item['addons'] as List<dynamic>?) ?? [];
          final notes = item['notes']?.toString();
          final isLast = item == items.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.pandaPinkLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$qty×',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pandaPinkDark)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black500)),
                    ),
                    Text(_money(price),
                        style: const TextStyle(fontSize: 14, color: AppColors.black500)),
                  ],
                ),
                if (addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 42, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: addons
                          .map((a) => Text('+ ${a['name']}',
                              style: const TextStyle(fontSize: 13, color: AppColors.gray900)))
                          .toList(),
                    ),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 42, top: 4),
                    child: Text('* $notes',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNote(Map<String, dynamic> order) {
    final note = order['deliveryNote']?.toString();
    if (note == null || note.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, size: 16, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF92400E), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(Map<String, dynamic> order) {
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final tax = (order['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final packaging = (order['packagingFee'] as num?)?.toDouble() ?? 0.0;
    final delivery = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final discount = (order['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final total = (order['grandTotal'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          _chargeRow('Sub total', _money(subtotal)),
          _chargeRow('(+) VAT', _money(tax)),
          _chargeRow('(+) Packaging charge', _money(packaging)),
          if (delivery > 0) _chargeRow('(+) Delivery fee', _money(delivery)),
          if (discount > 0)
            _chargeRow('(−) Discount', _money(discount), valueColor: AppColors.success),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, thickness: 0.5, color: AppColors.gray600),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black500)),
                Text(_money(total),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.pandaPink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.gray900)),
          Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, Map<String, dynamic> order, String? nextStatus,
      String? actionText, Color buttonColor, bool canSendPathao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: nextStatus != null
            ? SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _updateStatus(nextStatus),
                  child: Text(actionText ?? '',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              )
            : SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pandaPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showPathaoDialog(context, order['id'] as String),
                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                  label: const Text('Send to Pathao',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
      ),
    );
  }
}
