import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/common/breadcrumbs_with_heading.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_data_table.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_status_badge.dart';
import '../../data/banners_repository.dart';
import '../dialogs/banner_editor_dialog.dart';

/// Resolved presentation status for a banner: a display [label] and the
/// [StatusBadgeVariant] used to render its [WStatusBadge].
typedef _BannerStatus = ({String label, StatusBadgeVariant variant});

/// Banners management screen (Requirements 12.1, 12.4, 12.5, 12.6, 12.7).
///
/// Presentational redesign built on the standardized component library: a
/// [WDataTable] renders the paginated banner list with a 48x32 rounded
/// thumbnail, title, a status [WStatusBadge], the schedule range, sort order,
/// and row actions. The [BreadcrumbsWithHeading] page header carries a "New
/// Banner" primary action in its trailing slot. Create / edit open the
/// [BannerEditorDialog] ([WDialog]-based); delete uses a [WDialog] confirmation
/// with a destructive confirm button.
///
/// The existing Riverpod providers and repository flows are preserved unchanged
/// — the screen owns only presentation state (current page and page size).
///
/// Status mapping: a banner that is active and currently within its schedule
/// maps to `success`; an active banner whose start date is in the future maps
/// to `info` (scheduled); an expired or inactive banner maps to `neutral`.
class BannersManagementScreen extends ConsumerStatefulWidget {
  const BannersManagementScreen({super.key});

  @override
  ConsumerState<BannersManagementScreen> createState() =>
      _BannersManagementScreenState();
}

class _BannersManagementScreenState
    extends ConsumerState<BannersManagementScreen> {
  int _currentPage = 1;
  int _pageSize = WDataTable.defaultPageSize;

  void _showEditor([Map<String, dynamic>? banner]) {
    showDialog(
      context: context,
      builder: (_) => BannerEditorDialog(banner: banner),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> banner) async {
    final title = (banner['title'] ?? 'this banner').toString();

    final confirmed = await WDialog.show<bool>(
      context: context,
      title: 'Delete Banner?',
      subtitle: 'This action cannot be undone.',
      content: Text(
        'Are you sure you want to delete "$title"?',
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
      await ref.read(bannersRepositoryProvider).deleteBanner(banner['id']);
      ref.invalidate(bannersProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete the banner. Please try again."),
        ),
      );
    }
  }

  /// Returns the slice of [banners] for the current page after clamping the
  /// page against the available data.
  List<Map<String, dynamic>> _pageItems(List<Map<String, dynamic>> banners) {
    final totalPages =
        banners.isEmpty ? 1 : ((banners.length + _pageSize - 1) ~/ _pageSize);
    if (_currentPage > totalPages) {
      // Clamp after the data set shrinks (e.g. a deletion).
      _currentPage = totalPages;
    }
    final start = (_currentPage - 1) * _pageSize;
    if (start >= banners.length) return const [];
    final end = (start + _pageSize).clamp(0, banners.length);
    return banners.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bannersAsync = ref.watch(bannersProvider);

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbsWithHeading(
            heading: 'Promotional Banners',
            breadcrumbItems: const ['Dashboard', 'Banners'],
            trailing: WButton(
              label: 'New Banner',
              leadingIcon: Icons.add_photo_alternate_outlined,
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
              child: bannersAsync.when(
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
                      "We couldn't load the banners. Please try again.",
                  onRetry: () => ref.invalidate(bannersProvider),
                ),
                data: (banners) {
                  final pageItems = _pageItems(banners);
                  return WDataTable<Map<String, dynamic>>(
                    columns: _columns(),
                    data: pageItems,
                    currentPage: _currentPage,
                    totalItems: banners.length,
                    pageSize: _pageSize,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _currentPage = 1;
                    }),
                    emptyStateTitle: 'No banners found',
                    emptyStateSubtitle:
                        'Create your first promotional banner to get started.',
                    emptyStateIcon: Icons.photo_library_outlined,
                    emptyStateActionLabel: 'New Banner',
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
        label: 'Thumbnail',
        width: 120,
        cellBuilder: _buildThumbnailCell,
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Title',
        cellBuilder: (banner) => Text(
          (banner['title'] ?? 'Untitled Banner').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            weight: TypographyTokens.semibold,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Status',
        width: 140,
        cellBuilder: (banner) {
          final status = _statusOf(banner);
          return WStatusBadge(label: status.label, variant: status.variant);
        },
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Schedule',
        cellBuilder: (banner) => Text(
          _formatSchedule(
            banner['startsAt']?.toString(),
            banner['endsAt']?.toString(),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Sort Order',
        width: 120,
        cellBuilder: (banner) => Text(
          '${banner['sortOrder'] ?? 0}',
          style: context.tokens.typography.style(
            size: TypographyTokens.base,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      WTableColumn<Map<String, dynamic>>(
        label: 'Actions',
        width: 120,
        cellBuilder: _buildActionsCell,
      ),
    ];
  }

  Widget _buildThumbnailCell(Map<String, dynamic> banner) {
    final colors = context.colors;
    final imageUrl = (banner['imageUrl'] ?? '').toString();

    // 48x32 rounded thumbnail (radius sm) with neutral placeholder.
    return ClipRRect(
      borderRadius: RadiusTokens.borderRadiusSm,
      child: Container(
        width: 48,
        height: 32,
        color: colors.gray200,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholderIcon(colors),
              )
            : _placeholderIcon(colors),
      ),
    );
  }

  Widget _placeholderIcon(ColorTokens colors) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: colors.textSecondary,
        size: 18,
      ),
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> banner) {
    final colors = context.colors;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: colors.textSecondary,
          splashRadius: 20,
          tooltip: 'Edit Banner',
          onPressed: () => _showEditor(banner),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colors.error,
          splashRadius: 20,
          tooltip: 'Delete Banner',
          onPressed: () => _confirmDelete(banner),
        ),
      ],
    );
  }

  /// Resolves the display status and badge variant for [banner].
  ///
  /// - inactive → neutral ("Inactive")
  /// - expired (end date in the past) → neutral ("Expired")
  /// - scheduled (start date in the future) → info ("Scheduled")
  /// - otherwise active → success ("Active")
  _BannerStatus _statusOf(Map<String, dynamic> banner) {
    final isActive = banner['isActive'] == true;
    if (!isActive) {
      return (label: 'Inactive', variant: StatusBadgeVariant.neutral);
    }

    final now = DateTime.now();
    final startsAt = _parseDate(banner['startsAt']);
    final endsAt = _parseDate(banner['endsAt']);

    if (endsAt != null && endsAt.isBefore(now)) {
      return (label: 'Expired', variant: StatusBadgeVariant.neutral);
    }
    if (startsAt != null && startsAt.isAfter(now)) {
      return (label: 'Scheduled', variant: StatusBadgeVariant.info);
    }
    return (label: 'Active', variant: StatusBadgeVariant.success);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatSchedule(String? startsAt, String? endsAt) {
    String fmt(String iso) => iso.split('T').first;
    if (startsAt != null && endsAt != null) {
      return '${fmt(startsAt)} \u2013 ${fmt(endsAt)}';
    } else if (startsAt != null) {
      return 'Starts ${fmt(startsAt)}';
    } else if (endsAt != null) {
      return 'Ends ${fmt(endsAt)}';
    }
    return 'No schedule';
  }
}
