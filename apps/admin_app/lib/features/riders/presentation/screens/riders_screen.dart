import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_status_badge.dart';
import '../../../../core/widgets/status_mappings.dart';
import '../dialogs/rider_profile_dialog.dart';
import '../providers/riders_provider.dart';

/// Rider management screen (Requirement 11).
///
/// Presents riders in the standardized [WDataTable] with two tabs — Active
/// Riders and Pending Applications — and an approval workflow for pending
/// applications. The screen is purely presentational: it consumes the existing
/// [ridersProvider] and preserves the established Riverpod data flow and the
/// notifier's `approveRider` / `refresh` behaviour.
///
/// ## Approval workflow & error handling
///
/// * Approve / Reject delegate to [RidersNotifier.approveRider]. That notifier
///   only refreshes the list after a successful API call and rethrows on
///   failure, so a failed operation leaves the rider's status unchanged
///   (Requirement 11.6). The UI surfaces the failure via a SnackBar.
/// * On success the notifier re-fetches both lists, which moves an approved
///   rider into the Active tab and removes a rejected rider from the pending
///   list (Requirement 11.7).
/// * Rejection is gated behind a destructive confirmation dialog
///   (Requirement 11.5).
///
/// ## Note on the Approve button variant
///
/// Requirement 11.3 calls for a "success" button variant, but [WButton] only
/// defines primary / secondary / ghost / destructive variants. Per the task
/// guidance we use the existing [WButtonVariant.primary] for Approve and
/// [WButtonVariant.destructive] for Reject to stay consistent with the design
/// system rather than introducing a one-off success-coloured button.
class RidersScreen extends ConsumerStatefulWidget {
  const RidersScreen({super.key});

  @override
  ConsumerState<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends ConsumerState<RidersScreen> {
  /// 0 = Active Riders, 1 = Pending Applications.
  int _selectedTab = 0;

  /// Current 1-based page for the active tab (client-side pagination).
  int _currentPage = 1;

  /// Current page size for the active tab.
  int _pageSize = WDataTable.defaultPageSize;

  bool get _isPendingTab => _selectedTab == 1;

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
      _currentPage = 1; // Reset pagination when switching tabs.
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final stateAsync = ref.watch(ridersProvider);
    final RidersState? state = stateAsync.asData?.value;

    final activeRiders = state?.activeRiders ?? const <Map<String, dynamic>>[];
    final pendingRiders = state?.pendingRiders ?? const <Map<String, dynamic>>[];
    final riders = _isPendingTab ? pendingRiders : activeRiders;

    // Derive the current page slice (client-side pagination).
    final totalItems = riders.length;
    final totalPages = totalItems <= 0
        ? 1
        : ((totalItems + _pageSize - 1) ~/ _pageSize);
    final effectivePage = _currentPage.clamp(1, totalPages);
    final pageData = _pageSlice(riders, effectivePage, _pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page header: title + refresh.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rider Management',
              style: tokens.typography.style(
                size: TypographyTokens.xxl,
                weight: TypographyTokens.bold,
                color: colors.textPrimary,
              ),
            ),
            WButton(
              label: 'Refresh',
              variant: WButtonVariant.secondary,
              leadingIcon: Icons.refresh,
              isLoading: stateAsync.isLoading,
              onPressed: () => ref.read(ridersProvider.notifier).refresh(),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xxl),

        // Tab navigation (Active Riders / Pending Applications).
        _RiderTabBar(
          selectedIndex: _selectedTab,
          activeCount: state == null ? null : activeRiders.length,
          pendingCount: state == null ? null : pendingRiders.length,
          onSelected: _selectTab,
        ),
        const SizedBox(height: SpacingTokens.xxl),

        // Data table card.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: RadiusTokens.borderRadiusLg,
              border: Border.all(color: colors.border),
              boxShadow: ElevationTokens.sm,
            ),
            clipBehavior: Clip.antiAlias,
            child: WDataTable<Map<String, dynamic>>(
              columns: _buildColumns(),
              data: pageData,
              isLoading: stateAsync.isLoading,
              hasError: stateAsync.hasError,
              errorMessage:
                  "We couldn't load the riders. Please try again.",
              onRetry: () => ref.read(ridersProvider.notifier).refresh(),
              currentPage: effectivePage,
              totalItems: totalItems,
              pageSize: _pageSize,
              onPageChanged: (page) => setState(
                () => _currentPage = page.clamp(1, totalPages),
              ),
              onPageSizeChanged: (size) => setState(() {
                _pageSize = size;
                _currentPage = 1;
              }),
              emptyStateIcon: Icons.delivery_dining_outlined,
              emptyStateTitle: _isPendingTab
                  ? 'No pending applications'
                  : 'No active riders',
              emptyStateSubtitle: _isPendingTab
                  ? 'New rider applications will appear here for review.'
                  : 'Approved riders will appear here.',
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the slice of [all] for the given 1-based [page] and [size].
  List<T> _pageSlice<T>(List<T> all, int page, int size) {
    if (all.isEmpty || size <= 0) return all;
    final start = (page - 1) * size;
    if (start >= all.length) return const [];
    final end = math.min(start + size, all.length);
    return all.sublist(start, end);
  }

  /// Builds the table columns. The Actions column renders the approval buttons
  /// only on the Pending Applications tab (Requirement 11.3).
  List<WTableColumn<Map<String, dynamic>>> _buildColumns() {
    return [
      WTableColumn<Map<String, dynamic>>(
        label: 'Rider',
        cellBuilder: (rider) => _RiderCell(rider: rider),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Contact',
        cellBuilder: (rider) => _ContactCell(rider: rider),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Vehicle Type',
        cellBuilder: (rider) => _VehicleCell(rider: rider),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Status',
        cellBuilder: (rider) {
          final status = (rider['approvalStatus'] ?? 'UNKNOWN').toString();
          return WStatusBadge(
            label: status,
            variant: RiderStatusMapping.fromStatus(status),
          );
        },
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Actions',
        width: _isPendingTab ? 280 : 120,
        cellBuilder: (rider) => _buildActions(rider),
      ),
    ];
  }

  Widget _buildActions(Map<String, dynamic> rider) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isPendingTab) ...[
          WButton(
            label: 'Approve',
            size: WButtonSize.sm,
            leadingIcon: Icons.check,
            onPressed: () => _approve(rider),
          ),
          const SizedBox(width: SpacingTokens.sm),
          WButton(
            label: 'Reject',
            size: WButtonSize.sm,
            variant: WButtonVariant.destructive,
            leadingIcon: Icons.close,
            onPressed: () => _confirmReject(rider),
          ),
          const SizedBox(width: SpacingTokens.sm),
        ],
        IconButton(
          icon: const Icon(Icons.visibility_outlined),
          iconSize: 20,
          color: colors.textSecondary,
          tooltip: 'View Profile',
          onPressed: () => _viewProfile(rider),
        ),
      ],
    );
  }

  void _viewProfile(Map<String, dynamic> rider) {
    showDialog<void>(
      context: context,
      builder: (_) => RiderProfileDialog(rider: rider, isPending: _isPendingTab),
    );
  }

  Future<void> _approve(Map<String, dynamic> rider) async {
    await _updateApproval(rider, 'APPROVED');
  }

  /// Shows a destructive confirmation dialog before rejecting (Req 11.5).
  Future<void> _confirmReject(Map<String, dynamic> rider) async {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final name = (rider['fullName'] ?? 'this rider').toString();

    final confirmed = await WDialog.show<bool>(
      context: context,
      title: 'Reject Application',
      subtitle: 'This action cannot be undone.',
      content: Text(
        'Are you sure you want to reject the application from $name? '
        'They will not be able to operate as a rider.',
        style: typography.style(
          size: TypographyTokens.md,
          color: colors.textSecondary,
        ),
      ),
      actions: [
        WButton(
          label: 'Cancel',
          variant: WButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        WButton(
          label: 'Reject',
          variant: WButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (confirmed == true) {
      await _updateApproval(rider, 'REJECTED');
    }
  }

  /// Drives an approve/reject operation and surfaces success/failure feedback.
  ///
  /// On failure the rider's status is preserved unchanged because the notifier
  /// only refreshes after a successful API call (Requirement 11.6). On success
  /// the notifier refreshes both lists, moving the rider to the appropriate tab
  /// (Requirement 11.7).
  Future<void> _updateApproval(
    Map<String, dynamic> rider,
    String status,
  ) async {
    final id = rider['id']?.toString();
    if (id == null) return;

    try {
      await ref.read(ridersProvider.notifier).approveRider(id, status);
      if (!mounted) return;
      _showFeedback(
        status == 'APPROVED' ? 'Rider approved.' : 'Application rejected.',
        isError: false,
      );
    } catch (_) {
      if (!mounted) return;
      _showFeedback(
        status == 'APPROVED'
            ? "Couldn't approve the rider. Their status is unchanged."
            : "Couldn't reject the application. Their status is unchanged.",
        isError: true,
      );
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// The "Rider" cell: a 32px circular avatar with initials fallback + name
/// (Requirement 11.1).
class _RiderCell extends StatelessWidget {
  final Map<String, dynamic> rider;

  const _RiderCell({required this.rider});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final name = (rider['fullName'] ?? 'Unknown').toString();
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Row(
      children: [
        // 32px circular avatar (radius 16) with a primary tint background.
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: tokens.typography.style(
              size: TypographyTokens.sm,
              weight: TypographyTokens.semibold,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.style(
              size: TypographyTokens.base,
              weight: TypographyTokens.medium,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The "Contact" cell: the rider's phone number in the secondary text color.
class _ContactCell extends StatelessWidget {
  final Map<String, dynamic> rider;

  const _ContactCell({required this.rider});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      (rider['phone'] ?? 'N/A').toString(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tokens.typography.style(
        size: TypographyTokens.base,
        color: tokens.colors.textSecondary,
      ),
    );
  }
}

/// The "Vehicle Type" cell.
class _VehicleCell extends StatelessWidget {
  final Map<String, dynamic> rider;

  const _VehicleCell({required this.rider});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      (rider['vehicleType'] ?? 'N/A').toString(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tokens.typography.style(
        size: TypographyTokens.base,
        weight: TypographyTokens.medium,
        color: tokens.colors.textPrimary,
      ),
    );
  }
}

/// A custom, token-styled tab control for the riders screen (Requirement 11.2).
///
/// Renders the two tabs with a primary-coloured active indicator (3px bottom
/// border) and primary active text, while inactive tabs use the secondary text
/// colour. An optional count badge is shown once the riders data has loaded.
class _RiderTabBar extends StatelessWidget {
  final int selectedIndex;
  final int? activeCount;
  final int? pendingCount;
  final ValueChanged<int> onSelected;

  const _RiderTabBar({
    required this.selectedIndex,
    required this.activeCount,
    required this.pendingCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _RiderTab(
            label: 'Active Riders',
            count: activeCount,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _RiderTab(
            label: 'Pending Applications',
            count: pendingCount,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

/// A single tab within [_RiderTabBar].
class _RiderTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  /// Active indicator thickness (Requirement 11.2 — primary active indicator).
  static const double _indicatorThickness = 3;

  const _RiderTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final color = selected ? colors.primary : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.primary : Colors.transparent,
              width: _indicatorThickness,
            ),
          ),
        ),
        child: Text(
          count == null ? label : '$label ($count)',
          style: tokens.typography.style(
            size: TypographyTokens.md,
            weight: selected
                ? TypographyTokens.semibold
                : TypographyTokens.medium,
            color: color,
          ),
        ),
      ),
    );
  }
}
