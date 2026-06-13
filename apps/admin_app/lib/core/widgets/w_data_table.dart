import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';
import 'a11y/a11y_announcer.dart';
import 'w_empty_state.dart';
import 'w_error_state.dart';
import 'w_skeleton_loader.dart';

/// Describes a single column of a [WDataTable].
///
/// A column owns its header [label], a [cellBuilder] that renders the cell
/// content for a given data item, an optional [sortable] flag, and an optional
/// fixed [width].
class WTableColumn<T> {
  /// Header label. Rendered uppercase with the secondary text color.
  final String label;

  /// Builds the cell widget for [item] in this column.
  final Widget Function(T item) cellBuilder;

  /// Whether tapping the header toggles sorting for this column.
  final bool sortable;

  /// Optional fixed column width in logical pixels. When `null`, the column
  /// shares the available space evenly with the other flexible columns.
  final double? width;

  const WTableColumn({
    required this.label,
    required this.cellBuilder,
    this.sortable = false,
    this.width,
  });
}

/// Immutable sort state for a [WDataTable].
///
/// Exposes a pure [toggle] method so the sort-direction logic can be unit and
/// property tested independently of the widget tree (design Property 4 — sort
/// column toggle is an involution).
@immutable
class WTableSortState {
  /// The index of the currently sorted column, or `null` when unsorted.
  final int? columnIndex;

  /// Whether the active sort is ascending.
  final bool ascending;

  const WTableSortState({this.columnIndex, this.ascending = true});

  /// Returns the next sort state produced by tapping [tappedColumn]'s header.
  ///
  /// - Tapping the column that is already active flips the direction.
  /// - Tapping a different column activates it in ascending order.
  ///
  /// Because flipping is its own inverse, tapping the same active column twice
  /// returns the state to its original direction (an involution), satisfying
  /// design Property 4.
  WTableSortState toggle(int tappedColumn) {
    if (columnIndex == tappedColumn) {
      return WTableSortState(columnIndex: tappedColumn, ascending: !ascending);
    }
    return WTableSortState(columnIndex: tappedColumn, ascending: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WTableSortState &&
          runtimeType == other.runtimeType &&
          columnIndex == other.columnIndex &&
          ascending == other.ascending);

  @override
  int get hashCode => Object.hash(columnIndex, ascending);
}

/// Immutable pagination state for a [WDataTable].
///
/// Encapsulates the pure pagination arithmetic (total pages, navigation button
/// disabled states, and the displayed row range) so the logic can be unit and
/// property tested independently of the widget tree (design Property 5 —
/// pagination navigation button state correctness).
@immutable
class WTablePagination {
  /// The current page, 1-based.
  final int currentPage;

  /// The total number of items across all pages.
  final int totalItems;

  /// The number of rows shown per page.
  final int pageSize;

  const WTablePagination({
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
  });

  /// Total number of pages. Always at least 1 so an empty data set still
  /// reports a valid single page.
  int get totalPages {
    if (totalItems <= 0 || pageSize <= 0) return 1;
    return ((totalItems + pageSize - 1) ~/ pageSize);
  }

  /// Whether the previous-page button is disabled.
  ///
  /// Disabled if and only if [currentPage] is the first page (design
  /// Property 5).
  bool get isPreviousDisabled => currentPage <= 1;

  /// Whether the next-page button is disabled.
  ///
  /// Disabled if and only if [currentPage] is the last page (design
  /// Property 5).
  bool get isNextDisabled => currentPage >= totalPages;

  /// The 1-based index of the first row shown on the current page, or 0 when
  /// there are no items.
  int get rangeStart => totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;

  /// The 1-based index of the last row shown on the current page, clamped to
  /// [totalItems].
  int get rangeEnd => math.min(currentPage * pageSize, totalItems);
}

/// A polished, reusable, generic data table.
///
/// Wraps `data_table_2`'s [DataTable2] to render the current page of rows with
/// consistent styling (alternating gray50/white rows, 64px row height, hover
/// highlight, uppercase secondary-colored headers) and composes the shared
/// loading, error, and empty state widgets. Pagination and sorting are
/// parent-controlled: the widget reports interactions through callbacks and
/// renders according to the [currentPage], [pageSize], [sortColumnIndex], and
/// [sortAscending] inputs.
///
/// See Requirements 3.1–3.9 and 16.6, and design Properties 4 and 5.
class WDataTable<T> extends StatefulWidget {
  /// Column definitions, in display order.
  final List<WTableColumn<T>> columns;

  /// The data items for the current page.
  final List<T> data;

  /// When `true`, renders the table skeleton loader instead of rows.
  final bool isLoading;

  /// When `true`, renders the error state instead of rows.
  final bool hasError;

  /// Optional user-friendly error description shown in the error state.
  final String? errorMessage;

  /// Invoked when the user taps the error state's retry button.
  final VoidCallback? onRetry;

  /// The current page, 1-based.
  final int currentPage;

  /// The total number of items across all pages.
  final int totalItems;

  /// The number of rows per page. Expected to be one of [pageSizeOptions].
  final int pageSize;

  /// Invoked with the requested 1-based page when navigation buttons are used.
  final ValueChanged<int>? onPageChanged;

  /// Invoked with the newly selected page size from the size selector.
  final ValueChanged<int>? onPageSizeChanged;

  /// The index of the currently sorted column, or `null` when unsorted.
  final int? sortColumnIndex;

  /// Whether the active sort is ascending.
  final bool sortAscending;

  /// Invoked with the column index when a sortable header is tapped.
  final ValueChanged<int>? onSort;

  /// Invoked with the tapped item when a data row is tapped.
  final ValueChanged<T>? onRowTap;

  /// Title shown by the empty state when [data] is empty.
  final String emptyStateTitle;

  /// Optional subtitle shown by the empty state.
  final String? emptyStateSubtitle;

  /// Optional icon shown by the empty state.
  final IconData? emptyStateIcon;

  /// Optional action label shown by the empty state.
  final String? emptyStateActionLabel;

  /// Invoked when the empty state's action button is tapped.
  final VoidCallback? onEmptyStateAction;

  const WDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
    this.currentPage = 1,
    this.totalItems = 0,
    this.pageSize = defaultPageSize,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.onRowTap,
    this.emptyStateTitle = 'No data found',
    this.emptyStateSubtitle,
    this.emptyStateIcon = Icons.inbox_outlined,
    this.emptyStateActionLabel,
    this.onEmptyStateAction,
  });

  /// The minimum table width before horizontal scrolling engages (Req 3.1,
  /// 16.6).
  static const double minTableWidth = 1000;

  /// Fixed data row height in logical pixels (Req 3.1).
  static const double rowHeight = 64;

  /// Available page-size options for the selector (Req 3.8).
  static const List<int> pageSizeOptions = [10, 25, 50];

  /// Default page size (Req 3.8).
  static const int defaultPageSize = 10;

  @override
  State<WDataTable<T>> createState() => _WDataTableState<T>();
}

class _WDataTableState<T> extends State<WDataTable<T>> {
  /// The current pagination state derived from the widget inputs.
  WTablePagination get pagination => WTablePagination(
        currentPage: widget.currentPage,
        totalItems: widget.totalItems,
        pageSize: widget.pageSize,
      );

  @override
  void didUpdateWidget(covariant WDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Requirement 20.7: announce dynamic data changes (sorting, pagination, and
    // filtering that alters the row count) to assistive technology via a live
    // region within 500ms. The visible status line below is itself a live
    // region; this direct announcement guarantees delivery even when the line
    // text is unchanged (e.g. re-sorting the same page).
    final pageChanged = oldWidget.currentPage != widget.currentPage ||
        oldWidget.pageSize != widget.pageSize;
    final sortChanged = oldWidget.sortColumnIndex != widget.sortColumnIndex ||
        oldWidget.sortAscending != widget.sortAscending;
    final countChanged = oldWidget.totalItems != widget.totalItems;

    if (!widget.isLoading && !widget.hasError) {
      if (sortChanged && widget.sortColumnIndex != null) {
        final col = widget.sortColumnIndex!;
        final name = (col >= 0 && col < widget.columns.length)
            ? widget.columns[col].label
            : 'column';
        final dir = widget.sortAscending ? 'ascending' : 'descending';
        A11yAnnouncer.announce(context, 'Sorted by $name, $dir.');
      } else if (pageChanged || countChanged) {
        A11yAnnouncer.announce(context, _statusMessage());
      }
    }
  }

  /// Human-readable status describing the visible row range and total count.
  String _statusMessage() {
    final state = pagination;
    if (state.totalItems == 0) {
      return 'No results.';
    }
    return 'Showing ${state.rangeStart} to ${state.rangeEnd} of '
        '${state.totalItems} results.';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const WSkeletonLoader(variant: WSkeletonVariant.table);
    }

    if (widget.hasError) {
      return Center(
        child: WErrorState(
          message: widget.errorMessage,
          onRetry: widget.onRetry,
        ),
      );
    }

    if (widget.data.isEmpty) {
      return Center(
        child: WEmptyState(
          icon: widget.emptyStateIcon,
          title: widget.emptyStateTitle,
          subtitle: widget.emptyStateSubtitle,
          actionLabel: widget.emptyStateActionLabel,
          onAction: widget.onEmptyStateAction,
        ),
      );
    }

    // Requirement 20.5: identify the data table to assistive technology as a
    // single container so screen readers announce it as a table region.
    return Semantics(
      container: true,
      label: 'Data table',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTable(context)),
          // Requirement 20.7/20.8: a visually hidden live region that mirrors
          // the current row range so changes are announced without navigation.
          _buildLiveStatus(context),
          _buildPaginationControls(context),
        ],
      ),
    );
  }

  /// A visually hidden [Semantics] live region carrying the current status so
  /// assistive technology announces filtering/pagination results without the
  /// user navigating to it (Requirements 20.7, 20.8).
  Widget _buildLiveStatus(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _statusMessage(),
      child: const SizedBox(width: double.infinity, height: 0),
    );
  }

  /// Builds the [DataTable2] for the current page of [WDataTable.data].
  Widget _buildTable(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final typography = tokens.typography;

    final headingStyle = typography.style(
      size: TypographyTokens.sm,
      weight: TypographyTokens.semibold,
      color: colors.textSecondary,
    );

    return DataTable2(
      minWidth: WDataTable.minTableWidth,
      dataRowHeight: WDataTable.rowHeight,
      headingRowHeight: 48,
      horizontalMargin: SpacingTokens.lg,
      columnSpacing: SpacingTokens.md,
      showCheckboxColumn: false,
      dividerThickness: 0,
      headingTextStyle: headingStyle,
      headingRowColor: WidgetStatePropertyAll(colors.surface),
      sortColumnIndex: widget.sortColumnIndex,
      sortAscending: widget.sortAscending,
      columns: _buildColumns(headingStyle),
      rows: _buildRows(colors, typography),
    );
  }

  /// Maps the columns to `data_table_2` column definitions, wiring sort
  /// callbacks for sortable columns and uppercasing the header labels. Each
  /// header is marked as a column header for screen readers (Req 3.3, 3.7,
  /// 20.5).
  List<DataColumn2> _buildColumns(TextStyle headingStyle) {
    final columns = widget.columns;
    return [
      for (var i = 0; i < columns.length; i++)
        DataColumn2(
          label: Semantics(
            header: true,
            child: Text(
              columns[i].label.toUpperCase(),
              style: headingStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          fixedWidth: columns[i].width,
          onSort: columns[i].sortable && widget.onSort != null
              ? (columnIndex, _) => widget.onSort!(columnIndex)
              : null,
        ),
    ];
  }

  /// Builds one [DataRow2] per item, applying alternating background colors and
  /// a hover highlight (Req 3.1, 3.2).
  List<DataRow2> _buildRows(ColorTokens colors, TypographyTokens typography) {
    final data = widget.data;
    return [
      for (var i = 0; i < data.length; i++)
        DataRow2(
          specificRowHeight: WDataTable.rowHeight,
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return colors.gray100;
            }
            // Alternating row backgrounds: even rows gray50, odd rows surface.
            return i.isEven ? colors.gray50 : colors.surface;
          }),
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(data[i]) : null,
          cells: [
            for (final column in widget.columns)
              DataCell(
                DefaultTextStyle.merge(
                  style: typography.style(
                    size: TypographyTokens.base,
                    color: colors.textPrimary,
                  ),
                  child: column.cellBuilder(data[i]),
                ),
              ),
          ],
        ),
    ];
  }

  /// Builds the pagination footer: page-size selector, row-range indicator, and
  /// previous/next navigation buttons with correct disabled states (Req 3.8,
  /// 3.9).
  Widget _buildPaginationControls(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final typography = tokens.typography;
    final state = pagination;

    final labelStyle = typography.style(
      size: TypographyTokens.sm,
      color: colors.textSecondary,
    );

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text('Rows per page:', style: labelStyle),
          const SizedBox(width: SpacingTokens.sm),
          _buildPageSizeSelector(colors, typography),
          const Spacer(),
          Text(
            '${state.rangeStart}\u2013${state.rangeEnd} of ${state.totalItems}',
            style: labelStyle,
          ),
          const SizedBox(width: SpacingTokens.lg),
          _buildNavButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            color: colors,
            disabled: state.isPreviousDisabled,
            onPressed: () => widget.onPageChanged?.call(widget.currentPage - 1),
          ),
          const SizedBox(width: SpacingTokens.xs),
          _buildNavButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            color: colors,
            disabled: state.isNextDisabled,
            onPressed: () => widget.onPageChanged?.call(widget.currentPage + 1),
          ),
        ],
      ),
    );
  }

  /// Builds the page-size dropdown offering [WDataTable.pageSizeOptions]
  /// (Req 3.8).
  Widget _buildPageSizeSelector(ColorTokens colors, TypographyTokens typography) {
    return DropdownButton<int>(
      value: WDataTable.pageSizeOptions.contains(widget.pageSize)
          ? widget.pageSize
          : null,
      isDense: true,
      underline: const SizedBox.shrink(),
      borderRadius: RadiusTokens.borderRadiusMd,
      style: typography.style(
        size: TypographyTokens.sm,
        color: colors.textPrimary,
      ),
      items: [
        for (final option in WDataTable.pageSizeOptions)
          DropdownMenuItem<int>(
            value: option,
            child: Text('$option'),
          ),
      ],
      onChanged: widget.onPageSizeChanged == null
          ? null
          : (value) {
              if (value != null) widget.onPageSizeChanged!(value);
            },
    );
  }

  /// Builds a previous/next navigation icon button. When [disabled], the button
  /// renders muted and ignores taps (Req 3.9). The [tooltip] doubles as the
  /// button's semantic label for screen readers (Req 20.1).
  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required ColorTokens color,
    required bool disabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: disabled ? null : tooltip,
      // Keep a 44x44 hit target for keyboard/touch users (Req 20.3).
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      splashRadius: 22,
      color: color.textSecondary,
      disabledColor: color.textDisabled,
      onPressed: disabled ? null : onPressed,
    );
  }
}
