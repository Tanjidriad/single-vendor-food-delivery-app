import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/print_service.dart';

class EndOfDayScreen extends ConsumerStatefulWidget {
  final int totalOrders;
  final double netFoodSales;
  final List<dynamic> orders;
  final VoidCallback onRefresh;
  final VoidCallback onReopen;

  const EndOfDayScreen({
    super.key,
    required this.totalOrders,
    required this.netFoodSales,
    required this.orders,
    required this.onRefresh,
    required this.onReopen,
  });

  @override
  ConsumerState<EndOfDayScreen> createState() => _EndOfDayScreenState();
}

class _EndOfDayScreenState extends ConsumerState<EndOfDayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Derived numbers ──────────────────────────────────────────────
  double _sum(String key) => widget.orders.fold(
        0.0,
        (acc, o) => acc + ((o[key] as num?)?.toDouble() ?? 0.0),
      );

  double get _totalSubtotal => _sum('subtotal');
  double get _totalTax => _sum('taxAmount');
  double get _totalPackaging => _sum('packagingFee');
  double get _totalDeliveryFee => _sum('deliveryFee');

  bool _isCash(dynamic pm) {
    final s = pm?.toString().toUpperCase() ?? '';
    return s == 'COD' || s == 'CASH';
  }

  int get _cashOrders =>
      widget.orders.where((o) => _isCash(o['paymentMethod'])).length;
  int get _digitalOrders => widget.totalOrders - _cashOrders;
  int get _cancelledOrders => widget.orders
      .where((o) =>
          o['status'] == 'CANCELLED' || o['status'] == 'REJECTED')
      .length;
  int get _completedOrders => widget.totalOrders - _cancelledOrders;

  // ── Actions ──────────────────────────────────────────────────────
  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    await ref.read(printServiceProvider).printEndOfDayReport(widget.orders);
    if (mounted) setState(() => _isPrinting = false);
  }

  Future<void> _handleReopen() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new, color: AppColors.success),
            SizedBox(width: 8),
            Text('Re-open Restaurant?'),
          ],
        ),
        content: const Text(
          'This will put the kitchen back online and start accepting new orders immediately. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Re-open'),
          ),
        ],
      ),
    );
    if (confirm == true) widget.onReopen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(theme, isDark, dateStr, timeStr),
                      const SizedBox(height: 20),
                      _buildSalesCard(theme, isDark),
                      const SizedBox(height: 14),
                      _buildBreakdownCard(theme, isDark),
                      const SizedBox(height: 14),
                      _buildOrderMixCard(theme, isDark),
                      const SizedBox(height: 28),
                      _buildActions(theme),
                      const SizedBox(height: 16),
                      Text(
                        'Screen will unlock automatically when the restaurant re-opens.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(
      ThemeData theme, bool isDark, String dateStr, String timeStr) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.pandaPinkLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.nightlight_round,
              size: 36, color: AppColors.pandaPink),
        ),
        const SizedBox(height: 16),
        Text(
          'Restaurant Closed',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Closed at $timeStr',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── Big revenue card ─────────────────────────────────────────────
  Widget _buildSalesCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pandaPink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.pandaPink.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'NET FOOD SALES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'BDT ${widget.netFoodSales.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('Completed', '$_completedOrders orders',
                  Icons.check_circle_outline),
              const SizedBox(width: 24),
              _miniStat('Cancelled', '$_cancelledOrders orders',
                  Icons.cancel_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  // ── Breakdown card ───────────────────────────────────────────────
  Widget _buildBreakdownCard(ThemeData theme, bool isDark) {
    return _card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Sales Breakdown', Icons.pie_chart_outline, theme),
          const SizedBox(height: 14),
          _breakRow('Food Subtotal', _totalSubtotal, theme),
          _divider(theme),
          _breakRow('Packaging Fees', _totalPackaging, theme),
          _divider(theme),
          _breakRow('Tax / VAT', _totalTax, theme),
          _divider(theme),
          _breakRow('Net Food Sales', widget.netFoodSales, theme,
              isTotal: true),
          if (_totalDeliveryFee > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery fees collected: BDT ${_totalDeliveryFee.toStringAsFixed(2)}  (belongs to riders)',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Payment mix card ─────────────────────────────────────────────
  Widget _buildOrderMixCard(ThemeData theme, bool isDark) {
    return _card(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Payment Mix', Icons.credit_card_outlined, theme),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _paymentChip('Cash (COD)', _cashOrders,
                      AppColors.warning, AppColors.warningLight,
                      Icons.payments_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _paymentChip('Digital', _digitalOrders,
                      AppColors.info, AppColors.infoLight,
                      Icons.phonelink_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(String label, int count, Color color, Color bg,
      IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text('$count orders',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────
  Widget _buildActions(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isPrinting ? null : _handlePrint,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pandaPink),
              foregroundColor: AppColors.pandaPink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.pandaPink))
                : const Icon(Icons.print_outlined),
            label: Text(_isPrinting ? 'Printing…' : 'Print Z-Report'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.2)),
                    foregroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _handleReopen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Re-open'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────
  Widget _card(
      {required Widget child,
      required ThemeData theme,
      required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _breakRow(String label, double value, ThemeData theme,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight:
                  isTotal ? FontWeight.w800 : FontWeight.w500,
              color: theme.colorScheme.onSurface
                  .withValues(alpha: isTotal ? 1 : 0.7),
            ),
          ),
          Text(
            'BDT ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight:
                  isTotal ? FontWeight.w900 : FontWeight.w600,
              color:
                  isTotal ? AppColors.pandaPink : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) => Divider(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        height: 1,
        thickness: 1,
      );
}
