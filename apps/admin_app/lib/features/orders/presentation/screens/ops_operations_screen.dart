import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../data/ops_repository.dart';

typedef _Order = Map<String, dynamic>;
typedef _Refund = Map<String, dynamic>;

enum _OpsTab { stuck, failed, returned, refunds }

class OpsOperationsScreen extends ConsumerStatefulWidget {
  const OpsOperationsScreen({super.key});

  @override
  ConsumerState<OpsOperationsScreen> createState() =>
      _OpsOperationsScreenState();
}

class _OpsOperationsScreenState extends ConsumerState<OpsOperationsScreen> {
  _OpsTab _tab = _OpsTab.stuck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final queuesAsync = ref.watch(opsQueuesProvider);
    final refundsAsync = ref.watch(pendingRefundsProvider);

    return Container(
      color: colors.background,
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Operations',
            style: tokens.typography.style(
              size: TypographyTokens.xxl,
              weight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Stuck deliveries, failed orders, returned food, and refund queue.',
            style: tokens.typography.style(
              size: TypographyTokens.sm,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: _OpsTab.values.map((tab) {
              final count = _tabCount(tab, queuesAsync, refundsAsync);
              return _OpsTabChip(
                label: _tabLabel(tab, count),
                isActive: tab == _tab,
                onTap: () => setState(() => _tab = tab),
              );
            }).toList(),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Expanded(child: _buildTabBody(context, queuesAsync, refundsAsync)),
        ],
      ),
    );
  }

  String _tabLabel(_OpsTab tab, int count) {
    final base = switch (tab) {
      _OpsTab.stuck => 'Stuck in transit',
      _OpsTab.failed => 'Delivery failed',
      _OpsTab.returned => 'Returned food',
      _OpsTab.refunds => 'Refund queue',
    };
    return count > 0 ? '$base ($count)' : base;
  }

  int _tabCount(
    _OpsTab tab,
    AsyncValue<Map<String, dynamic>> queuesAsync,
    AsyncValue<List<_Refund>> refundsAsync,
  ) {
    return switch (tab) {
      _OpsTab.refunds => refundsAsync.maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      ),
      _ => queuesAsync.maybeWhen(
        data: (queues) {
          final key = switch (tab) {
            _OpsTab.stuck => 'stuckDeliveries',
            _OpsTab.failed => 'failedDeliveries',
            _OpsTab.returned => 'returnedOrders',
            _OpsTab.refunds => 'stuckDeliveries',
          };
          final list = queues[key];
          return list is List ? list.length : 0;
        },
        orElse: () => 0,
      ),
    };
  }

  Widget _buildTabBody(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> queuesAsync,
    AsyncValue<List<_Refund>> refundsAsync,
  ) {
    if (_tab == _OpsTab.refunds) {
      return refundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _errorState('Could not load refunds.'),
        data: (refunds) => _refundsTable(refunds),
      );
    }

    return queuesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _errorState('Could not load operations queues.'),
      data: (queues) {
        final key = switch (_tab) {
          _OpsTab.stuck => 'stuckDeliveries',
          _OpsTab.failed => 'failedDeliveries',
          _OpsTab.returned => 'returnedOrders',
          _OpsTab.refunds => 'stuckDeliveries',
        };
        final raw = queues[key];
        final orders = raw is List
            ? List<_Order>.from(
                raw.map((e) => Map<String, dynamic>.from(e as Map)),
              )
            : <_Order>[];
        return _ordersTable(orders);
      },
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: SpacingTokens.md),
          WButton(
            label: 'Retry',
            variant: WButtonVariant.secondary,
            onPressed: () {
              ref.invalidate(opsQueuesProvider);
              ref.invalidate(pendingRefundsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _ordersTable(List<_Order> orders) {
    return _card(
      WDataTable<_Order>(
        columns: [
          WTableColumn(
            label: 'Order',
            cellBuilder: (o) => Text('#${o['orderNumber'] ?? '—'}'),
          ),
          WTableColumn(
            label: 'Payment',
            cellBuilder: (o) => Text(_paymentLabel(o)),
          ),
          WTableColumn(label: 'SLA', cellBuilder: (o) => Text(_slaLabel(o))),
          WTableColumn(
            label: 'Actions',
            width: 160,
            cellBuilder: (o) => Row(
              children: [
                if (_tab == _OpsTab.stuck)
                  IconButton(
                    tooltip: 'Force unassign',
                    icon: const Icon(Icons.link_off, size: 18),
                    onPressed: () => _forceUnassign(o),
                  ),
                if (_tab == _OpsTab.failed)
                  IconButton(
                    tooltip: 'Resolve',
                    icon: const Icon(Icons.gavel_outlined, size: 18),
                    onPressed: () => _resolveFailed(o),
                  ),
              ],
            ),
          ),
        ],
        data: orders,
        emptyStateTitle: 'Queue is clear',
        emptyStateSubtitle: 'No orders need attention in this queue.',
        emptyStateIcon: Icons.check_circle_outline,
      ),
    );
  }

  Widget _refundsTable(List<_Refund> refunds) {
    return _card(
      WDataTable<_Refund>(
        columns: [
          WTableColumn(
            label: 'Order',
            cellBuilder: (r) {
              final order = r['order'];
              final num = order is Map ? order['orderNumber'] : null;
              return Text('#${num ?? '—'}');
            },
          ),
          WTableColumn(
            label: 'Amount',
            cellBuilder: (r) =>
                Text('৳${(r['amount'] as num?)?.toStringAsFixed(2) ?? '0'}'),
          ),
          WTableColumn(
            label: 'Reason',
            cellBuilder: (r) => Text(
              r['reason']?.toString() ?? '—',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          WTableColumn(
            label: 'Actions',
            width: 120,
            cellBuilder: (r) => IconButton(
              tooltip: 'Approve & execute',
              icon: const Icon(Icons.payments_outlined, size: 18),
              onPressed: () => _approveRefund(r),
            ),
          ),
        ],
        data: refunds,
        emptyStateTitle: 'No pending refunds',
        emptyStateSubtitle: 'Refund requests will appear here for approval.',
        emptyStateIcon: Icons.account_balance_wallet_outlined,
      ),
    );
  }

  Widget _card(Widget child) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: ClipRRect(borderRadius: RadiusTokens.borderRadiusLg, child: child),
    );
  }

  String _paymentLabel(_Order order) {
    final method = order['paymentMethod']?.toString() ?? 'COD';
    final status = order['paymentStatus']?.toString() ?? 'PENDING';
    if (method == 'ONLINE' && status == 'PAID') return 'Prepaid';
    if (method == 'ONLINE') return 'Unpaid';
    return 'COD';
  }

  String _slaLabel(_Order order) {
    final anchor = order['onTheWayAt'] ?? order['deliveryFailedAt'];
    if (anchor == null) return '—';
    final dt = DateTime.tryParse(anchor.toString());
    if (dt == null) return '—';
    final mins = DateTime.now().difference(dt.toLocal()).inMinutes;
    return '${mins}m ago';
  }

  Future<void> _forceUnassign(_Order order) async {
    final id = order['id']?.toString();
    if (id == null) return;
    try {
      await ref
          .read(opsRepositoryProvider)
          .forceUnassign(id, reason: 'admin_ops');
      ref.invalidate(opsQueuesProvider);
      _snack('Rider unassigned. Order will be re-offered.');
    } catch (_) {
      _snack('Could not force unassign. Try again.');
    }
  }

  Future<void> _resolveFailed(_Order order) async {
    final id = order['id']?.toString();
    if (id == null) return;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve delivery failure'),
        content: Text(
          'Order #${order['orderNumber']}\n\n'
          'Cancel + refund is recommended for prepaid orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'REASSIGN'),
            child: const Text('Reassign rider'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'CANCEL_REFUND'),
            child: const Text('Cancel & refund'),
          ),
        ],
      ),
    );

    if (action == null) return;
    try {
      await ref
          .read(opsRepositoryProvider)
          .resolveException(id, action: action);
      ref.invalidate(opsQueuesProvider);
      ref.invalidate(pendingRefundsProvider);
      _snack('Exception resolved.');
    } catch (_) {
      _snack('Could not resolve exception.');
    }
  }

  Future<void> _approveRefund(_Refund refund) async {
    final id = refund['id']?.toString();
    if (id == null) return;
    try {
      await ref
          .read(opsRepositoryProvider)
          .updateRefund(id, status: 'APPROVED');
      ref.invalidate(pendingRefundsProvider);
      _snack('Refund approved and queued for execution.');
    } catch (_) {
      _snack('Could not approve refund.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OpsTabChip extends StatelessWidget {
  const _OpsTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.surface,
            borderRadius: RadiusTokens.borderRadiusMd,
            border: Border.all(
              color: isActive ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: tokens.typography.style(
              size: TypographyTokens.sm,
              weight: TypographyTokens.semibold,
              color: isActive ? colors.onPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
