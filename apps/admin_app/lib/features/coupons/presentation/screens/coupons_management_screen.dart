import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/common/breadcrumbs_with_heading.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_status_badge.dart';
import '../../data/coupons_repository.dart';
import '../dialogs/coupon_editor_dialog.dart';

/// Coupons management screen (Requirements 12.2, 12.4, 12.5, 12.6, 12.7).
///
/// Presentational redesign built on the standardized component library: a
/// [WDataTable] renders the paginated coupon list with columns Code, Discount
/// (value + type), Min Order Amount, Valid Period, Status, and Actions. The
/// page header reuses [BreadcrumbsWithHeading] with a "New Coupon" primary
/// action in the trailing slot. Create / edit open the [CouponEditorDialog]
/// (built on [WDialog]); delete uses a [WDialog] confirmation with a
/// destructive confirm button.
///
/// Status badge variant choice (Requirement 12.2 — active / expired):
/// - Expired (valid-until in the past) → `neutral` (a terminal, non-error
///   state).
/// - Active (`isActive` true and not expired) → `success`.
/// - Inactive (`isActive` false and not expired) → `neutral`.
///
/// The existing Riverpod providers and repository flows are preserved
/// unchanged. The screen owns only presentation state: the current page and
/// page size.
class CouponsManagementScreen extends ConsumerStatefulWidget {
  const CouponsManagementScreen({super.key});

  @override
  ConsumerState<CouponsManagementScreen> createState() =>
      _CouponsManagementScreenState();
}

class _CouponsManagementScreenState
    extends ConsumerState<CouponsManagementScreen> {
  int _currentPage = 1;
  int _pageSize = WDataTable.defaultPageSize;

  void _showEditor([Map<String, dynamic>? coupon]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CouponEditorDialog(coupon: coupon),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> coupon) async {
    final code = (coupon['code'] ?? 'this coupon').toString();

    final confirmed = await WDialog.show<bool>(
      context: context,
      title: 'Delete Coupon?',
      subtitle: 'This action cannot be undone.',
      content: Text(
        'Are you sure you want to delete "$code"?',
        style: context.tokens.typography.style(
          size: TypographyTokens.base,
          color: context.colors.textSecondary,
        ),
      ),
      actions: [
        Builder(
          builder: (dialogContext) => WButton(
            label: 'Cancel',
            variant: WButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
        ),
        Builder(
          builder: (dialogContext) => WButton(
            label: 'Delete',
            variant: WButtonVariant.destructive,
            leadingIcon: Icons.delete_outline,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ),
      ],
    );

    if (confirmed != true) return;

    try {
      await ref.read(couponsRepositoryProvider).deleteCoupon(coupon['id']);
      ref.invalidate(couponsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete the coupon. Please try again."),
        ),
      );
    }
  }

  /// Returns the slice of [coupons] for the current page after clamping the
  /// page against the available data.
  List<Map<String, dynamic>> _pageItems(List<Map<String, dynamic>> coupons) {
    final totalPages =
        coupons.isEmpty ? 1 : ((coupons.length + _pageSize - 1) ~/ _pageSize);
    if (_currentPage > totalPages) {
      // Clamp after the data set shrinks (e.g. a deletion).
      _currentPage = totalPages;
    }
    final start = (_currentPage - 1) * _pageSize;
    if (start >= coupons.length) return const [];
    final end = (start + _pageSize).clamp(0, coupons.length);
    return coupons.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final couponsAsync = ref.watch(couponsProvider);

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbsWithHeading(
            heading: 'Coupons & Offers',
            breadcrumbItems: const ['Dashboard', 'Marketing', 'Coupons'],
            trailing: WButton(
              label: 'New Coupon',
              leadingIcon: Icons.add,
              size: WButtonSize.lg,
              onPressed: () => _showEditor(),
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: RadiusTokens.borderRadiusLg,
                border: Border.all(color: colors.border),
                boxShadow: ElevationTokens.sm,
              ),
              clipBehavior: Clip.antiAlias,
              child: couponsAsync.when(
                loading: () => WDataTable<Map<String, dynamic>>(
                  columns: _columns(),
                  data: const [],
                  isLoading: true,
                ),
                error: (err, stack) => WDataTable<Map<String, dynamic>>(
                  columns: _columns(),
                  data: const [],
                  hasError: true,
                  errorMessage:
                      "We couldn't load the coupons. Please try again.",
                  onRetry: () => ref.invalidate(couponsProvider),
                ),
                data: (coupons) {
                  final pageItems = _pageItems(coupons);
                  return WDataTable<Map<String, dynamic>>(
                    columns: _columns(),
                    data: pageItems,
                    currentPage: _currentPage,
                    totalItems: coupons.length,
                    pageSize: _pageSize,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _currentPage = 1;
                    }),
                    emptyStateTitle: 'No coupons found',
                    emptyStateSubtitle:
                        'Create your first promotional coupon to get started.',
                    emptyStateIcon: Icons.local_offer_outlined,
                    emptyStateActionLabel: 'New Coupon',
                    onEmptyStateAction: () => _showEditor(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<WTableColumn<Map<String, dynamic>>> _columns() {
    return [
      WTableColumn<Map<String, dynamic>>(
        label: 'Code',
        cellBuilder: _buildCodeCell,
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Discount',
        cellBuilder: _buildDiscountCell,
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Min Order',
        cellBuilder: (coupon) => Text(
          _formatCurrency(coupon['minOrderAmount']),
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Valid Period',
        cellBuilder: (coupon) => Text(
          _formatPeriod(coupon['validFrom'], coupon['validUntil']),
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Status',
        cellBuilder: _buildStatusCell,
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Actions',
        cellBuilder: _buildActionsCell,
      ),
    ];
  }

  Widget _buildCodeCell(Map<String, dynamic> coupon) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Row(
      children: [
        Icon(Icons.local_offer_outlined, size: 18, color: colors.primary),
        const SizedBox(width: SpacingTokens.sm),
        Flexible(
          child: Text(
            (coupon['code'] ?? 'UNKNOWN').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.style(
              size: TypographyTokens.base,
              weight: TypographyTokens.semibold,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountCell(Map<String, dynamic> coupon) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final isPercentage = coupon['discountType'] == 'PERCENTAGE';
    final value = coupon['discountValue'];
    final valueText =
        isPercentage ? '${_formatNumber(value)}%' : _formatCurrency(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          valueText,
          style: typography.style(
            size: TypographyTokens.base,
            weight: TypographyTokens.semibold,
            color: colors.textPrimary,
          ),
        ),
        Text(
          isPercentage ? 'Percentage' : 'Flat amount',
          style: typography.style(
            size: TypographyTokens.xs,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCell(Map<String, dynamic> coupon) {
    final validUntil = coupon['validUntil'] != null
        ? DateTime.tryParse(coupon['validUntil'].toString())
        : null;
    final isExpired = validUntil != null && validUntil.isBefore(DateTime.now());
    final isActive = coupon['isActive'] == true;

    final (label, variant) = isExpired
        ? ('Expired', StatusBadgeVariant.neutral)
        : isActive
            ? ('Active', StatusBadgeVariant.success)
            : ('Inactive', StatusBadgeVariant.neutral);

    return WStatusBadge(label: label, variant: variant);
  }

  Widget _buildActionsCell(Map<String, dynamic> coupon) {
    final colors = context.colors;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: colors.textSecondary,
          splashRadius: 20,
          tooltip: 'Edit Coupon',
          onPressed: () => _showEditor(coupon),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colors.error,
          splashRadius: 20,
          tooltip: 'Delete Coupon',
          onPressed: () => _confirmDelete(coupon),
        ),
      ],
    );
  }

  /// Formats a numeric-ish [value] as a currency amount (e.g. `$5.00`).
  String _formatCurrency(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    return '\$${(number ?? 0).toStringAsFixed(2)}';
  }

  /// Formats a numeric-ish [value] without forcing decimals (e.g. `20`).
  String _formatNumber(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (number == null) return '0';
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toString();
  }

  /// Formats the coupon's valid period from ISO date strings.
  String _formatPeriod(dynamic from, dynamic until) {
    String fmt(String iso) => iso.split('T').first;
    final fromStr = from?.toString();
    final untilStr = until?.toString();
    if (fromStr != null && untilStr != null) {
      return '${fmt(fromStr)} \u2192 ${fmt(untilStr)}';
    } else if (fromStr != null) {
      return 'From ${fmt(fromStr)}';
    } else if (untilStr != null) {
      return 'Until ${fmt(untilStr)}';
    }
    return 'No expiration';
  }
}
