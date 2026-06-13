import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/common/breadcrumbs_with_heading.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../data/menu_repository.dart';
import '../dialogs/menu_item_editor_dialog.dart';

/// Menu management screen (Requirement 9).
///
/// Presentational redesign built on the standardized component library: a
/// [WDataTable] renders the paginated item list with a 40x40 rounded thumbnail,
/// category, price, an availability [Switch] (success color when active), and
/// row actions. Add / edit open the [MenuItemEditorDialog]; delete uses a
/// [WDialog] confirmation with a destructive confirm button.
///
/// The existing Riverpod providers and repository flows are preserved. The
/// screen owns only presentation state: the current page, page size, and an
/// optimistic availability override map used to revert the toggle when an
/// update fails (Requirement 9.8).
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  int _currentPage = 1;
  int _pageSize = WDataTable.defaultPageSize;

  /// Optimistic availability values keyed by item id. An entry is present only
  /// while a toggle is in-flight or after it succeeds; it is removed (reverting
  /// to the server value) when the update fails (Requirement 9.8).
  final Map<String, bool> _availabilityOverrides = {};

  void _showEditor([dynamic item]) {
    showDialog(
      context: context,
      builder: (_) => MenuItemEditorDialog(item: item),
    );
  }

  bool _isAvailable(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    return _availabilityOverrides[id] ?? (item['isAvailable'] ?? false);
  }

  /// Toggles availability optimistically and reverts on API failure
  /// (Requirement 9.8).
  Future<void> _toggleAvailability(Map<String, dynamic> item, bool val) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _availabilityOverrides[id] = val);

    try {
      final repo = ref.read(menuRepositoryProvider);
      await repo.updateItem(id, {'isAvailable': val});
      ref.invalidate(menuItemsProvider);
    } catch (_) {
      if (!mounted) return;
      // Revert the toggle to its previous state and surface an error.
      setState(() => _availabilityOverrides.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update availability. Please try again."),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final name = (item['name'] ?? 'this item').toString();

    final confirmed = await WDialog.show<bool>(
      context: context,
      title: 'Delete Item?',
      subtitle: 'This action cannot be undone.',
      content: Text(
        'Are you sure you want to delete "$name"?',
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
      final repo = ref.read(menuRepositoryProvider);
      await repo.deleteItem(item['id']);
      ref.invalidate(menuItemsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete the item. Please try again."),
        ),
      );
    }
  }

  /// Returns the slice of [items] for the current page after clamping the page
  /// against the available data.
  List<Map<String, dynamic>> _pageItems(List<Map<String, dynamic>> items) {
    final totalPages =
        items.isEmpty ? 1 : ((items.length + _pageSize - 1) ~/ _pageSize);
    if (_currentPage > totalPages) {
      // Clamp after the data set shrinks (e.g. a deletion).
      _currentPage = totalPages;
    }
    final start = (_currentPage - 1) * _pageSize;
    if (start >= items.length) return const [];
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final menuAsync = ref.watch(menuItemsProvider);

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbsWithHeading(
            heading: 'Menu Management',
            breadcrumbItems: const ['Dashboard', 'Menu'],
            trailing: WButton(
              label: 'Add New Item',
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
              child: menuAsync.when(
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
                      "We couldn't load the menu items. Please try again.",
                  onRetry: () => ref.invalidate(menuItemsProvider),
                ),
                data: (items) {
                  final pageItems = _pageItems(items);
                  return WDataTable<Map<String, dynamic>>(
                    columns: _columns(),
                    data: pageItems,
                    currentPage: _currentPage,
                    totalItems: items.length,
                    pageSize: _pageSize,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _currentPage = 1;
                    }),
                    emptyStateTitle: 'No menu items found',
                    emptyStateSubtitle:
                        'Add your first menu item to get started.',
                    emptyStateIcon: Icons.restaurant_menu,
                    emptyStateActionLabel: 'Add New Item',
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
        label: 'Item',
        cellBuilder: _buildItemCell,
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Category',
        cellBuilder: (item) => Text(
          (item['category'] ?? 'Uncategorized').toString(),
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Price',
        cellBuilder: (item) => Text(
          '\$${((item['price'] as num?) ?? 0).toStringAsFixed(2)}',
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            weight: TypographyTokens.semibold,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Availability',
        cellBuilder: (item) => Switch(
          value: _isAvailable(item),
          activeThumbColor: context.colors.success,
          onChanged: (val) => _toggleAvailability(item, val),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Actions',
        cellBuilder: _buildActionsCell,
      ),
    ];
  }

  Widget _buildItemCell(Map<String, dynamic> item) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final name = (item['name'] ?? '').toString();

    return Row(
      children: [
        // 40x40 rounded thumbnail (radius sm) with neutral placeholder.
        ClipRRect(
          borderRadius: RadiusTokens.borderRadiusSm,
          child: Container(
            width: 40,
            height: 40,
            color: colors.gray200,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholderIcon(colors),
                  )
                : _placeholderIcon(colors),
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Flexible(
          child: Text(
            name,
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

  Widget _placeholderIcon(ColorTokens colors) {
    return Center(
      child: Icon(
        Icons.fastfood_outlined,
        color: colors.textSecondary,
        size: 20,
      ),
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> item) {
    final colors = context.colors;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: colors.textSecondary,
          splashRadius: 20,
          tooltip: 'Edit Item',
          onPressed: () => _showEditor(item),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colors.error,
          splashRadius: 20,
          tooltip: 'Delete Item',
          onPressed: () => _confirmDelete(item),
        ),
      ],
    );
  }
}
