import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/common/breadcrumbs_with_heading.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_empty_state.dart';
import '../../../../core/widgets/w_error_state.dart';
import '../../../../core/widgets/w_select_input.dart';
import '../../../../core/widgets/w_skeleton_loader.dart';
import '../../domain/media_item.dart';
import '../../providers/media_provider.dart';

/// Media library management screen (Requirement 12.3–12.7).
///
/// Presentational redesign built on the standardized component library. Images
/// are presented as a responsive card grid of fixed 160x160 thumbnails (radius
/// `lg`); hovering a card reveals an overlay with Copy URL and Delete actions
/// in management mode. The page header uses [BreadcrumbsWithHeading] with an
/// "Upload Image" primary action in the trailing slot. Deletion is gated behind
/// a [WDialog] confirmation with a destructive confirm button, and loading /
/// error / empty states use the shared state widgets.
///
/// The screen doubles as a media picker: when [onImageSelected] is provided
/// (the [isDialog] flow used by `MediaPickerWidget`), tapping a card returns its
/// URL to the caller instead of exposing destructive actions. All existing
/// Riverpod providers and repository flows are preserved unchanged.
class MediaManagementScreen extends ConsumerWidget {
  final Function(String url)? onImageSelected;
  final bool isDialog;

  const MediaManagementScreen({
    super.key,
    this.onImageSelected,
    this.isDialog = false,
  });

  /// The media folder categories surfaced in the folder selector.
  static const List<SelectOption> _categoryOptions = [
    SelectOption(value: 'MENU', label: 'Menu Items'),
    SelectOption(value: 'BANNER', label: 'Banners'),
    SelectOption(value: 'CATEGORY', label: 'Categories'),
    SelectOption(value: 'OTHER', label: 'Others'),
  ];

  bool get _isPicker => onImageSelected != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mediaAsync = ref.watch(mediaListProvider);
    final category = ref.watch(mediaCategoryProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        const SizedBox(height: SpacingTokens.xxl),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: RadiusTokens.borderRadiusLg,
              border: Border.all(color: colors.border),
              boxShadow: ElevationTokens.sm,
            ),
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolbar(context, ref, category),
                const SizedBox(height: SpacingTokens.xxl),
                Expanded(child: _buildBody(context, ref, mediaAsync)),
              ],
            ),
          ),
        ),
      ],
    );

    // Picker/dialog mode renders inside a fixed-size dialog surface and needs
    // its own padding; route mode relies on the AppShell's content padding.
    if (isDialog) {
      return Material(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.xxl),
          child: content,
        ),
      );
    }
    return content;
  }

  // --- Header -----------------------------------------------------------

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final uploadButton = WButton(
      label: 'Upload Image',
      leadingIcon: Icons.cloud_upload_outlined,
      size: WButtonSize.lg,
      onPressed: () => _uploadImage(ref),
    );

    if (isDialog) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Media',
            style: context.tokens.typography.style(
              size: TypographyTokens.xl,
              weight: TypographyTokens.bold,
              color: context.colors.textPrimary,
            ),
          ),
          uploadButton,
        ],
      );
    }

    return BreadcrumbsWithHeading(
      heading: 'Media Library',
      breadcrumbItems: const ['Dashboard', 'Media'],
      trailing: uploadButton,
    );
  }

  // --- Toolbar (folder selector) ---------------------------------------

  Widget _buildToolbar(BuildContext context, WidgetRef ref, String category) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    final selected = _categoryOptions.firstWhere(
      (option) => option.value == category,
      orElse: () => _categoryOptions.first,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Media Folders',
          style: typography.style(
            size: TypographyTokens.lg,
            weight: TypographyTokens.semibold,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(
          width: 220,
          child: WSelectInput(
            options: _categoryOptions,
            value: selected,
            onChanged: (option) => ref
                .read(mediaCategoryProvider.notifier)
                .setCategory(option.value),
          ),
        ),
      ],
    );
  }

  // --- Body / states ----------------------------------------------------

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MediaItem>> mediaAsync,
  ) {
    return mediaAsync.when(
      loading: () => _buildLoadingGrid(),
      error: (error, stack) => WErrorState(
        message: "We couldn't load the media library. Please try again.",
        onRetry: () => ref.read(mediaListProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return WEmptyState(
            icon: Icons.image_outlined,
            title: 'No images found',
            subtitle: 'Upload your first image to this folder to get started.',
            actionLabel: 'Upload Image',
            onAction: () => _uploadImage(ref),
          );
        }
        return _buildGrid(context, ref, items);
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> items,
  ) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: SpacingTokens.lg,
        runSpacing: SpacingTokens.lg,
        children: [
          for (final item in items)
            _MediaCard(
              item: item,
              isSelectable: _isPicker,
              onSelect: _isPicker
                  ? () {
                      Navigator.of(context).pop();
                      onImageSelected!(item.url);
                    }
                  : null,
              onCopyUrl: _isPicker ? null : () => _copyUrl(context, item.url),
              onDelete:
                  _isPicker ? null : () => _confirmDelete(context, ref, item),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: SpacingTokens.lg,
        runSpacing: SpacingTokens.lg,
        children: [
          for (var i = 0; i < 8; i++)
            const SizedBox(
              width: _MediaCard.thumbnailSize,
              child: WSkeletonLoader(
                variant: WSkeletonVariant.generic,
                height: _MediaCard.thumbnailSize,
              ),
            ),
        ],
      ),
    );
  }

  // --- Actions ----------------------------------------------------------

  Future<void> _uploadImage(WidgetRef ref) async {
    final category = ref.read(mediaCategoryProvider);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ref.read(mediaListProvider.notifier).uploadMedia(image, category);
    }
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image URL copied to clipboard')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final confirmed = await WDialog.show<bool>(
      context: context,
      title: 'Delete Image?',
      subtitle: 'This action cannot be undone.',
      content: Text(
        'Are you sure you want to delete "${item.filename}"?',
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
      await ref.read(mediaListProvider.notifier).deleteMedia(item.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete the image. Please try again."),
        ),
      );
    }
  }
}

/// A single media thumbnail card with a hover-revealed action overlay.
///
/// Renders a fixed 160x160 thumbnail (radius `lg`) above an ellipsised
/// filename. A [MouseRegion] tracks hover to reveal the overlay:
/// - In picker mode ([isSelectable]) the overlay invites selection and tapping
///   the card returns the image via [onSelect].
/// - Otherwise the overlay exposes Copy URL ([onCopyUrl]) and Delete
///   ([onDelete]) circular action buttons.
class _MediaCard extends StatefulWidget {
  final MediaItem item;
  final bool isSelectable;
  final VoidCallback? onSelect;
  final VoidCallback? onCopyUrl;
  final VoidCallback? onDelete;

  const _MediaCard({
    required this.item,
    required this.isSelectable,
    this.onSelect,
    this.onCopyUrl,
    this.onDelete,
  });

  /// Fixed thumbnail dimension per Requirement 12.3.
  static const double thumbnailSize = 160;

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return SizedBox(
      width: _MediaCard.thumbnailSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: widget.isSelectable
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: widget.isSelectable ? widget.onSelect : null,
              child: ClipRRect(
                borderRadius: RadiusTokens.borderRadiusLg,
                child: Stack(
                  children: [
                    Container(
                      width: _MediaCard.thumbnailSize,
                      height: _MediaCard.thumbnailSize,
                      color: colors.gray200,
                      child: Image.network(
                        widget.item.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(colors),
                      ),
                    ),
                    // Resting 1px border for definition against the surface.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: RadiusTokens.borderRadiusLg,
                            border: Border.all(color: colors.border),
                          ),
                        ),
                      ),
                    ),
                    if (_hovered)
                      Positioned.fill(
                        child: _buildOverlay(colors, typography),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            widget.item.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.style(
              size: TypographyTokens.sm,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorTokens colors) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildOverlay(ColorTokens colors, TypographyTokens typography) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: RadiusTokens.borderRadiusLg,
      ),
      child: Center(
        child: widget.isSelectable
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Select',
                    style: typography.style(
                      size: TypographyTokens.sm,
                      weight: TypographyTokens.semibold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleAction(
                    colors: colors,
                    icon: Icons.link_outlined,
                    tooltip: 'Copy URL',
                    onTap: widget.onCopyUrl,
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  _circleAction(
                    colors: colors,
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onTap: widget.onDelete,
                    danger: true,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _circleAction({
    required ColorTokens colors,
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Icon(
              icon,
              size: 20,
              color: danger ? colors.error : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
