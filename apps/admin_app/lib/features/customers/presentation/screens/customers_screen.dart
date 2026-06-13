import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/layouts/breakpoints.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_search_input.dart';
import '../../../../core/widgets/w_status_badge.dart';
import '../../../../core/widgets/status_mappings.dart';
import '../../data/customers_repository.dart';

/// Customers management screen.
///
/// A searchable customer list rendered with the standardized [WDataTable]
/// (Requirement 10). The redesign is purely presentational: it consumes the
/// existing [customersListProvider] and preserves the established Riverpod data
/// flow, layering search, pagination, customer avatars, and a View Profile
/// dialog on top.
///
/// Covers Requirements 10.1–10.6:
/// * 10.1 — DataTable columns: Customer (avatar + name), Contact, Total Orders,
///   Total Spent, Join Date, Actions.
/// * 10.2 — name/email search with a 300ms debounce (via [WSearchInput]).
/// * 10.3 — 32px circular avatars with initials fallback over a primary-at-10%
///   alpha background.
/// * 10.4 — View Profile dialog with contact info and up to 10 recent orders.
/// * 10.5 — standardized empty state when the search yields no matches.
/// * 10.6 — full list restored when the search query is cleared.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  /// The active, debounced search query.
  String _query = '';

  /// The current 1-based pagination page.
  int _currentPage = 1;

  /// The active page size.
  int _pageSize = WDataTable.defaultPageSize;

  /// Filters [customers] by name or email against the lowercased [query]
  /// (Requirement 10.2). An empty query restores the full list
  /// (Requirement 10.6).
  List<Map<String, dynamic>> _filterCustomers(
    List<Map<String, dynamic>> customers,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? c['contact'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      // Reset to the first page so results are visible regardless of the page
      // the user was previously on.
      _currentPage = 1;
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _onPageSizeChanged(int size) {
    setState(() {
      _pageSize = size;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final customersAsync = ref.watch(customersListProvider);

    return Container(
      color: colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mode = Breakpoints.fromWidth(constraints.maxWidth);
          final padding = _contentPadding(mode);

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onSearchChanged: _onSearchChanged,
                  stack: mode == LayoutMode.compact,
                ),
                const SizedBox(height: SpacingTokens.xxl),
                Expanded(
                  child: _CustomersCard(
                    child: customersAsync.when(
                      loading: () => _buildTable(
                        const [],
                        isLoading: true,
                      ),
                      error: (_, _) => _buildTable(
                        const [],
                        hasError: true,
                      ),
                      data: (customers) {
                        final filtered = _filterCustomers(customers, _query);
                        return _buildTable(filtered);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the [WDataTable], slicing [filtered] to the current page and wiring
  /// the empty/error/loading states.
  Widget _buildTable(
    List<Map<String, dynamic>> filtered, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    final totalItems = filtered.length;
    final pagination = WTablePagination(
      currentPage: _currentPage,
      totalItems: totalItems,
      pageSize: _pageSize,
    );

    // Clamp the page in case filtering shrank the result set below the current
    // page; render using the effective page without mutating state mid-build.
    final effectivePage = _currentPage > pagination.totalPages
        ? pagination.totalPages
        : _currentPage;

    final startIndex = (effectivePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageItems = startIndex >= totalItems
        ? const <Map<String, dynamic>>[]
        : filtered.sublist(startIndex, endIndex);

    final searching = _query.trim().isNotEmpty;

    return WDataTable<Map<String, dynamic>>(
      isLoading: isLoading,
      hasError: hasError,
      errorMessage:
          "We couldn't load the customers list. Please try again.",
      onRetry: () => ref.invalidate(customersListProvider),
      currentPage: effectivePage,
      totalItems: totalItems,
      pageSize: _pageSize,
      onPageChanged: _onPageChanged,
      onPageSizeChanged: _onPageSizeChanged,
      emptyStateIcon:
          searching ? Icons.search_off_outlined : Icons.people_outline,
      emptyStateTitle:
          searching ? 'No matching customers' : 'No customers found',
      emptyStateSubtitle: searching
          ? 'No customers match "${_query.trim()}". Try a different name or email.'
          : 'Customers will appear here once they place their first order.',
      data: pageItems,
      columns: [
        WTableColumn<Map<String, dynamic>>(
          label: 'Customer',
          cellBuilder: (c) => _CustomerCell(
            name: (c['name'] ?? 'Unknown').toString(),
          ),
        ),
        WTableColumn<Map<String, dynamic>>(
          label: 'Contact',
          cellBuilder: (c) => _MutedText(
            (c['email'] ?? c['contact'] ?? '—').toString(),
          ),
        ),
        WTableColumn<Map<String, dynamic>>(
          label: 'Total Orders',
          cellBuilder: (c) => _StrongText(
            _orderCount(c).toString(),
          ),
        ),
        WTableColumn<Map<String, dynamic>>(
          label: 'Total Spent',
          cellBuilder: (c) => _PriceText(_totalSpent(c)),
        ),
        WTableColumn<Map<String, dynamic>>(
          label: 'Join Date',
          cellBuilder: (c) => _MutedText(
            _formatDate((c['joinDate'] ?? c['createdAt'])?.toString()),
          ),
        ),
        WTableColumn<Map<String, dynamic>>(
          label: 'Actions',
          width: 96,
          cellBuilder: (c) => _RowActions(
            onViewProfile: () => _showProfileDialog(c),
          ),
        ),
      ],
    );
  }

  /// Opens the View Profile dialog for [customer] (Requirement 10.4).
  void _showProfileDialog(Map<String, dynamic> customer) {
    final name = (customer['name'] ?? 'Customer').toString();
    final email = (customer['email'] ?? customer['contact'] ?? '—').toString();

    WDialog.show(
      context: context,
      title: name,
      subtitle: email,
      content: _CustomerProfileContent(customer: customer),
      actions: [
        WButton(
          label: 'Close',
          variant: WButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Content-area padding per breakpoint (Requirement 16.7).
  static double _contentPadding(LayoutMode mode) => switch (mode) {
        LayoutMode.expanded => SpacingTokens.xxxl, // 32px
        LayoutMode.medium => SpacingTokens.xxl, // 24px
        LayoutMode.compact => SpacingTokens.lg, // 16px
      };
}

// ---------------------------------------------------------------------------
// Field helpers
// ---------------------------------------------------------------------------

int _orderCount(Map<String, dynamic> c) {
  final raw = c['totalOrders'] ?? c['orderCount'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

double _totalSpent(Map<String, dynamic> c) {
  final raw = c['totalSpent'] ?? c['totalSpend'];
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

/// Formats an optional date [value] for display.
///
/// Parses ISO-8601 strings into a compact `MMM d, yyyy` label; otherwise
/// returns the original string (or an em dash when empty/null).
String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

/// Computes 1–2 character initials from a [name] for the avatar fallback.
String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Page header: title and the debounced customer search input.
class _Header extends StatelessWidget {
  const _Header({required this.onSearchChanged, required this.stack});

  final ValueChanged<String> onSearchChanged;

  /// When `true` (compact viewport) the title and search stack vertically.
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    final title = Text(
      'Customers',
      style: tokens.typography.style(
        size: TypographyTokens.xxl,
        weight: TypographyTokens.bold,
        color: colors.textPrimary,
      ),
    );

    final search = WSearchInput(
      placeholder: 'Search by name or email...',
      onChanged: onSearchChanged,
    );

    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: SpacingTokens.lg),
          search,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: SpacingTokens.lg),
        SizedBox(width: 280, child: search),
      ],
    );
  }
}

/// Surface card wrapping the data table with a token-driven border and shadow.
class _CustomersCard extends StatelessWidget {
  const _CustomersCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusLg,
        border: Border.all(color: colors.border),
        boxShadow: ElevationTokens.sm,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Cells
// ---------------------------------------------------------------------------

/// Customer cell: a 32px initials avatar followed by the customer name.
class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Row(
      children: [
        _CustomerAvatar(name: name),
        const SizedBox(width: SpacingTokens.md),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.style(
              size: TypographyTokens.base,
              weight: TypographyTokens.semibold,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A 32px circular avatar with an initials fallback over a primary-at-10%
/// alpha background (Requirement 10.3).
class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.name});

  final String name;

  /// Fixed avatar diameter in logical pixels (Requirement 10.3).
  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initialsFor(name),
        style: tokens.typography.style(
          size: TypographyTokens.sm,
          weight: TypographyTokens.semibold,
          color: colors.primary,
        ),
      ),
    );
  }
}

/// Secondary-colored, single-line text cell.
class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: tokens.typography.style(
        size: TypographyTokens.base,
        color: tokens.colors.textSecondary,
      ),
    );
  }
}

/// Emphasized primary-text cell (e.g. order counts).
class _StrongText extends StatelessWidget {
  const _StrongText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text,
      style: tokens.typography.style(
        size: TypographyTokens.base,
        weight: TypographyTokens.semibold,
        color: tokens.colors.textPrimary,
      ),
    );
  }
}

/// Currency cell rendered in the primary accent color.
class _PriceText extends StatelessWidget {
  const _PriceText(this.amount);

  final double amount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      '\$${amount.toStringAsFixed(2)}',
      style: tokens.typography.style(
        size: TypographyTokens.base,
        weight: TypographyTokens.bold,
        color: tokens.colors.primary,
      ),
    );
  }
}

/// Row-level actions: a single View Profile icon button.
class _RowActions extends StatelessWidget {
  const _RowActions({required this.onViewProfile});

  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      icon: const Icon(Icons.visibility_outlined, size: 18),
      color: colors.textSecondary,
      splashRadius: 20,
      tooltip: 'View Profile',
      onPressed: onViewProfile,
    );
  }
}

// ---------------------------------------------------------------------------
// View Profile dialog content
// ---------------------------------------------------------------------------

/// Body of the View Profile dialog (Requirement 10.4).
///
/// Shows contact information (name, email, phone) and the most recent orders
/// (up to 10) with each order's date, status badge, and total.
class _CustomerProfileContent extends StatelessWidget {
  const _CustomerProfileContent({required this.customer});

  final Map<String, dynamic> customer;

  /// Maximum number of recent orders displayed (Requirement 10.4).
  static const int _maxRecentOrders = 10;

  List<Map<String, dynamic>> get _recentOrders {
    final raw = customer['recentOrders'] ?? customer['orders'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .take(_maxRecentOrders)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    final name = (customer['name'] ?? 'Unknown').toString();
    final email = (customer['email'] ?? customer['contact'] ?? '—').toString();
    final phone = (customer['phone'] ?? customer['phoneNumber'] ?? '—')
        .toString();

    final orders = _recentOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionLabel('Contact Information'),
        const SizedBox(height: SpacingTokens.md),
        _InfoRow(icon: Icons.person_outline, label: 'Name', value: name),
        const SizedBox(height: SpacingTokens.sm),
        _InfoRow(icon: Icons.mail_outline, label: 'Email', value: email),
        const SizedBox(height: SpacingTokens.sm),
        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
        const SizedBox(height: SpacingTokens.xl),
        _SectionLabel('Recent Orders'),
        const SizedBox(height: SpacingTokens.md),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: Text(
              'No recent orders for this customer.',
              style: tokens.typography.style(
                size: TypographyTokens.sm,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          ...orders.map((o) => _RecentOrderRow(order: o)),
      ],
    );
  }
}

/// Uppercase section label used inside the profile dialog.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text.toUpperCase(),
      style: tokens.typography.style(
        size: TypographyTokens.xs,
        weight: TypographyTokens.semibold,
        color: tokens.colors.textSecondary,
      ),
    );
  }
}

/// A single contact-info row: leading icon, label, and value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: SpacingTokens.sm),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: tokens.typography.style(
              size: TypographyTokens.sm,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Text(
            value,
            style: tokens.typography.style(
              size: TypographyTokens.sm,
              weight: TypographyTokens.medium,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single recent-order row: date, status badge, and total.
class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;

    final status =
        (order['status'] ?? 'PENDING').toString().toUpperCase();
    final date = _formatDate(
      (order['date'] ?? order['createdAt'] ?? order['orderDate'])?.toString(),
    );
    final total = _orderTotal(order);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date,
              style: tokens.typography.style(
                size: TypographyTokens.sm,
                color: colors.textPrimary,
              ),
            ),
          ),
          WStatusBadge(
            label: status.replaceAll('_', ' '),
            variant: OrderStatusMapping.fromStatus(status),
          ),
          const SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 72,
            child: Text(
              '\$${total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: tokens.typography.style(
                size: TypographyTokens.sm,
                weight: TypographyTokens.semibold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _orderTotal(Map<String, dynamic> order) {
    final raw = order['total'] ?? order['grandTotal'] ?? order['amount'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
