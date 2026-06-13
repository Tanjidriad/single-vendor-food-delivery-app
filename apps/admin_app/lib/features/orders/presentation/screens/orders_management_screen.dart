import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/layouts/breakpoints.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_status_badge.dart';
import '../../../../core/widgets/status_mappings.dart';
import '../../data/orders_repository.dart';

/// Convenience alias for the loosely-typed order maps returned by the backend.
typedef _Order = Map<String, dynamic>;

/// The filter chips shown above the orders table.
///
/// Each chip maps to a phase of the order lifecycle. `All` matches every order
/// and is active by default on screen load (Requirement 8.2).
enum _OrderFilter { all, preparing, onTheWay, delivered, failed, cancelled }

extension _OrderFilterX on _OrderFilter {
  /// The human-readable chip label.
  String get label => switch (this) {
        _OrderFilter.all => 'All',
        _OrderFilter.preparing => 'Preparing',
        _OrderFilter.onTheWay => 'On the Way',
        _OrderFilter.delivered => 'Delivered',
        _OrderFilter.failed => 'Failed',
        _OrderFilter.cancelled => 'Cancelled',
      };

  /// Whether an order with the given backend [status] belongs to this filter.
  ///
  /// Backend statuses are grouped into the lifecycle phases represented by the
  /// chips (Requirement 8.3). The `All` chip matches everything.
  bool matches(String status) {
    final s = status.toUpperCase();
    return switch (this) {
      _OrderFilter.all => true,
      _OrderFilter.preparing =>
        const {'PLACED', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP'}.contains(s),
      _OrderFilter.onTheWay => const {'PICKED_UP', 'ON_THE_WAY'}.contains(s),
      _OrderFilter.delivered => s == 'DELIVERED',
      _OrderFilter.failed => const {
        'DELIVERY_FAILED',
        'RETURNED_TO_RESTAURANT',
      }.contains(s),
      _OrderFilter.cancelled => s == 'CANCELLED',
    };
  }
}

/// Live orders management screen.
///
/// Presents restaurant orders in the standardized [WDataTable] with working
/// filter chips, semantic status badges, and row-level actions (View Details,
/// Update Status). The screen is purely presentational — it consumes the
/// existing [liveOrdersProvider] and [ordersRepositoryProvider] and preserves
/// the established Riverpod data flow (Requirement 8).
class OrdersManagementScreen extends ConsumerStatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  ConsumerState<OrdersManagementScreen> createState() =>
      _OrdersManagementScreenState();
}

class _OrdersManagementScreenState
    extends ConsumerState<OrdersManagementScreen> {
  _OrderFilter _activeFilter = _OrderFilter.all;
  int _currentPage = 1;
  int _pageSize = WDataTable.defaultPageSize;

  void _onFilterSelected(_OrderFilter filter) {
    if (filter == _activeFilter) return;
    setState(() {
      _activeFilter = filter;
      _currentPage = 1; // Reset to the first page when the filter changes.
    });
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _onPageSizeChanged(int size) {
    setState(() {
      _pageSize = size;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ordersAsync = ref.watch(liveOrdersProvider);

    return Container(
      color: colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding =
              _contentPadding(Breakpoints.fromWidth(constraints.maxWidth));

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: SpacingTokens.xxl),
                Expanded(child: _buildTableCard(context, ordersAsync)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Content-area padding per breakpoint (Requirement 16.7).
  static double _contentPadding(LayoutMode mode) => switch (mode) {
        LayoutMode.expanded => SpacingTokens.xxxl, // 32px
        LayoutMode.medium => SpacingTokens.xxl, // 24px
        LayoutMode.compact => SpacingTokens.lg, // 16px
      };

  /// Builds the screen header: title on the left, filter chips on the right.
  Widget _buildHeader(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Live Orders',
          style: tokens.typography.style(
            size: TypographyTokens.xxl,
            weight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: SpacingTokens.xl),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: [
              for (final filter in _OrderFilter.values)
                _FilterChip(
                  label: filter.label,
                  isActive: filter == _activeFilter,
                  onTap: () => _onFilterSelected(filter),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Wraps a table [child] in the standardized card container.
  Widget _tableCard(BuildContext context, Widget child) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: ClipRRect(
        borderRadius: RadiusTokens.borderRadiusLg,
        child: child,
      ),
    );
  }

  /// Resolves the loading / error / data state into a [WDataTable] card.
  Widget _buildTableCard(
    BuildContext context,
    AsyncValue<List<_Order>> ordersAsync,
  ) {
    final columns = _buildColumns(context);

    return ordersAsync.when(
      loading: () => _tableCard(
        context,
        WDataTable<_Order>(columns: columns, data: const [], isLoading: true),
      ),
      error: (_, _) => _tableCard(
        context,
        WDataTable<_Order>(
          columns: columns,
          data: const [],
          hasError: true,
          errorMessage:
              "We couldn't load orders right now. Please try again.",
          onRetry: () => ref.invalidate(liveOrdersProvider),
        ),
      ),
      data: (orders) {
        final filtered = orders
            .where((o) => _activeFilter.matches(_statusOf(o)))
            .toList();

        final pagination = WTablePagination(
          currentPage: _currentPage,
          totalItems: filtered.length,
          pageSize: _pageSize,
        );
        // Clamp the page in case filtering shrank the result set.
        final page = _currentPage.clamp(1, pagination.totalPages);
        final start = (page - 1) * _pageSize;
        final pageData = filtered.skip(start).take(_pageSize).toList();

        return _tableCard(
          context,
          WDataTable<_Order>(
            columns: columns,
            data: pageData,
            currentPage: page,
            totalItems: filtered.length,
            pageSize: _pageSize,
            onPageChanged: _onPageChanged,
            onPageSizeChanged: _onPageSizeChanged,
            emptyStateTitle: 'No orders found',
            emptyStateSubtitle: _activeFilter == _OrderFilter.all
                ? 'New orders will appear here as they come in.'
                : 'No orders match the "${_activeFilter.label}" filter.',
            emptyStateIcon: Icons.receipt_long_outlined,
          ),
        );
      },
    );
  }

  /// Column definitions for the orders table (Requirement 8.1).
  List<WTableColumn<_Order>> _buildColumns(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return [
      WTableColumn<_Order>(
        label: 'Order ID',
        cellBuilder: (order) => Text(
          _orderIdOf(order),
          style: tokens.typography.style(
            size: TypographyTokens.base,
            weight: TypographyTokens.semibold,
            color: colors.textPrimary,
          ),
        ),
      ),
      WTableColumn<_Order>(
        label: 'Customer',
        cellBuilder: (order) => Text(
          (order['customerName'] as String?)?.trim().isNotEmpty == true
              ? order['customerName'] as String
              : 'Unknown',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      WTableColumn<_Order>(
        label: 'Items',
        cellBuilder: (order) => Text(
          _itemsSummary(order),
          style: tokens.typography.style(
            size: TypographyTokens.base,
            color: colors.textSecondary,
          ),
        ),
      ),
      WTableColumn<_Order>(
        label: 'Total',
        cellBuilder: (order) => Text(
          _formatCurrency(order['grandTotal']),
          style: tokens.typography.style(
            size: TypographyTokens.base,
            weight: TypographyTokens.bold,
            color: colors.primary,
          ),
        ),
      ),
      WTableColumn<_Order>(
        label: 'Payment',
        cellBuilder: (order) => Text(_paymentLabel(order)),
      ),
      WTableColumn<_Order>(
        label: 'Status',
        cellBuilder: (order) {
          final status = _statusOf(order);
          return WStatusBadge(
            label: status.replaceAll('_', ' '),
            variant: _badgeVariant(status),
          );
        },
      ),
      WTableColumn<_Order>(
        label: 'Actions',
        width: 120,
        cellBuilder: (order) => Row(
          children: [
            _ActionIcon(
              icon: Icons.visibility_outlined,
              tooltip: 'View Details',
              onPressed: () => _showOrderDetails(order),
            ),
            const SizedBox(width: SpacingTokens.xs),
            _ActionIcon(
              icon: Icons.sync,
              tooltip: 'Update Status',
              onPressed: () => _showUpdateStatus(order),
            ),
          ],
        ),
      ),
    ];
  }

  /// Opens the View Details dialog showing full order information
  /// (Requirement 8.7).
  void _showOrderDetails(_Order order) {
    WDialog.show(
      context: context,
      title: 'Order ${_orderIdOf(order)}',
      subtitle: _statusOf(order).replaceAll('_', ' '),
      content: _OrderDetailsContent(order: order),
      actions: [
        WButton(
          label: 'Close',
          variant: WButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Opens the Update Status dialog with the available next-status options and
  /// a confirmation action (Requirement 8.8).
  void _showUpdateStatus(_Order order) {
    final current = _statusOf(order);
    final options = _nextStatuses(current);
    final orderId = order['id']?.toString();

    final selected = ValueNotifier<String?>(null);
    final isSubmitting = ValueNotifier<bool>(false);

    Future<void> submit() async {
      final status = selected.value;
      if (status == null || orderId == null) return;
      isSubmitting.value = true;
      try {
        await ref
            .read(ordersRepositoryProvider)
            .updateOrderStatus(orderId, status);
        ref.invalidate(liveOrdersProvider); // Refresh the table (Req 8.8).
        if (!mounted) return;
        Navigator.of(context).pop();
        _showSnack('Order status updated to ${status.replaceAll('_', ' ')}.');
      } catch (_) {
        isSubmitting.value = false;
        if (!mounted) return;
        _showSnack('Could not update the order status. Please try again.');
      }
    }

    WDialog.show(
      context: context,
      title: 'Update Status',
      subtitle: 'Order ${_orderIdOf(order)} — currently '
          '${current.replaceAll('_', ' ')}',
      content: options.isEmpty
          ? _NoTransitionsMessage(status: current)
          : _StatusOptions(options: options, selected: selected),
      actions: options.isEmpty
          ? [
              WButton(
                label: 'Close',
                variant: WButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]
          : [
              WButton(
                label: 'Cancel',
                variant: WButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isSubmitting,
                builder: (_, submitting, _) => ValueListenableBuilder<String?>(
                  valueListenable: selected,
                  builder: (_, value, _) => WButton(
                    label: 'Update Status',
                    isLoading: submitting,
                    isDisabled: value == null,
                    onPressed: value == null ? null : submit,
                  ),
                ),
              ),
            ],
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Extracts the order status, defaulting to `PLACED` when absent.
String _statusOf(_Order order) =>
    (order['status']?.toString() ?? 'PLACED').toUpperCase();

/// Builds the display order id, preferring the human-friendly order number.
String _orderIdOf(_Order order) {
  final number = order['orderNumber']?.toString();
  if (number != null && number.isNotEmpty) return '#$number';
  final id = order['id']?.toString();
  if (id != null && id.isNotEmpty) {
    return '#${id.length > 8 ? id.substring(0, 8) : id}';
  }
  return '#??';
}

/// Summarizes the order's line items as a total quantity count.
String _itemsSummary(_Order order) {
  final items = order['items'];
  if (items is List && items.isNotEmpty) {
    final count = items.fold<int>(
      0,
      (sum, item) =>
          sum + (((item as Map)['quantity'] as num?)?.toInt() ?? 0),
    );
    return '$count item${count == 1 ? '' : 's'}';
  }
  final summary = order['itemsSummary'];
  if (summary != null) return summary.toString();
  return '0 items';
}

String _paymentLabel(_Order order) {
  final method = order['paymentMethod']?.toString() ?? 'COD';
  final status = order['paymentStatus']?.toString() ?? 'PENDING';
  if (method == 'ONLINE' && status == 'PAID') return 'Prepaid';
  if (method == 'ONLINE') return 'Unpaid';
  return 'COD';
}

/// Formats a numeric amount as a USD currency string.
String _formatCurrency(dynamic value) {
  final amount = (value as num?)?.toDouble() ?? 0.0;
  return '\$${amount.toStringAsFixed(2)}';
}

/// Formats an ISO date string into a compact local date-time.
String _formatDate(dynamic value) {
  if (value == null) return '—';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  final dt = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

/// Adapts a backend order status to a [StatusBadgeVariant] using the
/// design-system [OrderStatusMapping].
///
/// The backend uses a more granular lifecycle than the predefined mapping
/// keys, so statuses are normalized to a mapping key first (Requirement 8.5).
StatusBadgeVariant _badgeVariant(String status) {
  final key = switch (status.toUpperCase()) {
    'PLACED' || 'ACCEPTED' => 'PENDING',
    'PREPARING' || 'READY_FOR_PICKUP' => 'PREPARING',
    'PICKED_UP' || 'ON_THE_WAY' => 'ON_THE_WAY',
    'DELIVERED' => 'DELIVERED',
    'CANCELLED' => 'CANCELLED',
    _ => status.toUpperCase(),
  };
  return OrderStatusMapping.fromStatus(key);
}

/// The valid next statuses an order may transition to from [current].
List<String> _nextStatuses(String current) {
  return switch (current.toUpperCase()) {
    'PLACED' => const ['ACCEPTED', 'CANCELLED'],
    'ACCEPTED' => const ['PREPARING', 'CANCELLED'],
    'PREPARING' => const ['READY_FOR_PICKUP', 'CANCELLED'],
    'READY_FOR_PICKUP' => const ['PICKED_UP', 'CANCELLED'],
    'PICKED_UP' => const ['ON_THE_WAY', 'CANCELLED'],
    'ON_THE_WAY' => const ['DELIVERED'],
    _ => const [],
  };
}

/// A filter chip rendered with the active/inactive treatment from
/// Requirement 8.4: active = filled primary background with white text;
/// inactive = outlined with secondary text.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.borderRadiusMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
              weight: isActive
                  ? TypographyTokens.semibold
                  : TypographyTokens.medium,
              color: isActive ? colors.onPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact icon button used for row-level actions, with a tooltip
/// (Requirement 8.6).
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      color: colors.textSecondary,
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Scrollable body for the View Details dialog: customer details, item list,
/// totals, and an order timeline (Requirement 8.7).
class _OrderDetailsContent extends StatelessWidget {
  final _Order order;

  const _OrderDetailsContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _section(context, 'Customer'),
        _row(context, 'Name', order['customerName']?.toString() ?? 'Unknown'),
        _row(context, 'Phone', order['customerPhone']?.toString() ?? '—'),
        if (order['deliveryAddress'] != null)
          _row(context, 'Address', order['deliveryAddress'].toString()),
        const SizedBox(height: SpacingTokens.xl),

        _section(context, 'Items'),
        if (items.isEmpty)
          _muted(context, 'No items on this order.')
        else
          ...items.map((raw) {
            final item = raw as Map;
            final name = item['name']?.toString() ?? 'Item';
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            final lineTotal = item['lineTotal'];
            return _row(context, '$qty × $name', _formatCurrency(lineTotal));
          }),
        const SizedBox(height: SpacingTokens.xl),

        _section(context, 'Summary'),
        _row(context, 'Subtotal', _formatCurrency(order['subtotal'])),
        if ((order['discountAmount'] as num?) != null &&
            (order['discountAmount'] as num) > 0)
          _row(context, 'Discount',
              '-${_formatCurrency(order['discountAmount'])}'),
        if ((order['deliveryFee'] as num?) != null &&
            (order['deliveryFee'] as num) > 0)
          _row(context, 'Delivery Fee', _formatCurrency(order['deliveryFee'])),
        if ((order['taxAmount'] as num?) != null &&
            (order['taxAmount'] as num) > 0)
          _row(context, 'Tax', _formatCurrency(order['taxAmount'])),
        _row(context, 'Total', _formatCurrency(order['grandTotal']),
            emphasize: true),
        const SizedBox(height: SpacingTokens.xl),

        _section(context, 'Timeline'),
        ..._timelineRows(context),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  List<Widget> _timelineRows(BuildContext context) {
    final entries = <MapEntry<String, dynamic>>[
      MapEntry('Placed', order['placedAt'] ?? order['createdAt']),
      MapEntry('Accepted', order['acceptedAt']),
      MapEntry('Ready', order['readyAt']),
      MapEntry('Delivered', order['deliveredAt']),
      MapEntry('Cancelled', order['cancelledAt']),
    ].where((e) => e.value != null).toList();

    if (entries.isEmpty) {
      return [_muted(context, 'No timeline information available.')];
    }
    return [
      for (final entry in entries)
        _row(context, entry.key, _formatDate(entry.value)),
    ];
  }

  Widget _section(BuildContext context, String title) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Text(
        title.toUpperCase(),
        style: tokens.typography.style(
          size: TypographyTokens.xs,
          weight: TypographyTokens.semibold,
          color: tokens.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: tokens.typography.style(
                size: TypographyTokens.base,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            value,
            textAlign: TextAlign.right,
            style: tokens.typography.style(
              size: TypographyTokens.base,
              weight: emphasize
                  ? TypographyTokens.bold
                  : TypographyTokens.medium,
              color: emphasize ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _muted(BuildContext context, String text) {
    final tokens = context.tokens;
    return Text(
      text,
      style: tokens.typography.style(
        size: TypographyTokens.sm,
        color: tokens.colors.textSecondary,
      ),
    );
  }
}

/// A selectable list of next-status options for the Update Status dialog.
class _StatusOptions extends StatefulWidget {
  final List<String> options;
  final ValueNotifier<String?> selected;

  const _StatusOptions({required this.options, required this.selected});

  @override
  State<_StatusOptions> createState() => _StatusOptionsState();
}

class _StatusOptionsState extends State<_StatusOptions> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select the new status for this order:',
          style: tokens.typography.style(
            size: TypographyTokens.sm,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        for (final status in widget.options)
          _StatusOptionTile(
            label: status.replaceAll('_', ' '),
            selected: widget.selected.value == status,
            onTap: () => setState(() => widget.selected.value = status),
          ),
      ],
    );
  }
}

/// A single selectable status option, rendered as a radio-style row that does
/// not rely on the deprecated [RadioListTile] group API.
class _StatusOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Text(
                  label,
                  style: tokens.typography.style(
                    size: TypographyTokens.base,
                    weight: selected
                        ? TypographyTokens.semibold
                        : TypographyTokens.regular,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message shown when an order is in a terminal state with no next statuses.
class _NoTransitionsMessage extends StatelessWidget {
  final String status;

  const _NoTransitionsMessage({required this.status});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      'This order is ${status.replaceAll('_', ' ').toLowerCase()} and has no '
      'further status updates available.',
      style: tokens.typography.style(
        size: TypographyTokens.base,
        color: tokens.colors.textSecondary,
      ),
    );
  }
}
