import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/inputs/media_picker_widget.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_text_input.dart';
import '../../data/banners_repository.dart';

/// Create / edit banner dialog (Requirements 12.4, 12.5).
///
/// Presentational redesign built on the standardized component library:
/// [WDialog] for the modal chrome, [WTextInput] for fields with inline
/// validation errors, the shared [MediaPickerWidget] for the banner image, and
/// [WButton] for the footer actions. The data layer, Riverpod providers, and
/// create / update flows are preserved unchanged.
class BannerEditorDialog extends ConsumerStatefulWidget {
  /// The existing banner map when editing, or `null` when creating.
  final Map<String, dynamic>? banner;

  const BannerEditorDialog({super.key, this.banner});

  @override
  ConsumerState<BannerEditorDialog> createState() =>
      _BannerEditorDialogState();
}

class _BannerEditorDialogState extends ConsumerState<BannerEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _linkUrlController;
  late final TextEditingController _sortOrderController;

  String _imageUrl = '';
  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isLoading = false;

  // Inline validation errors.
  String? _titleError;
  String? _imageError;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?['title'] ?? '');
    _imageUrl = b?['imageUrl'] ?? '';
    _linkUrlController = TextEditingController(text: b?['linkUrl'] ?? '');
    _sortOrderController =
        TextEditingController(text: (b?['sortOrder'] ?? 0).toString());
    _isActive = b?['isActive'] ?? true;
    _startsAt = b?['startsAt'] != null ? DateTime.parse(b!['startsAt']) : null;
    _endsAt = b?['endsAt'] != null ? DateTime.parse(b!['endsAt']) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  /// Validates the required fields (title, image) and populates the inline
  /// error strings. Returns `true` when the form may be submitted.
  bool _validate() {
    String? titleError;
    String? imageError;

    if (_titleController.text.trim().isEmpty) {
      titleError = 'Title is required';
    }
    if (_imageUrl.isEmpty) {
      imageError = 'Banner image is required';
    }

    setState(() {
      _titleError = titleError;
      _imageError = imageError;
    });

    return titleError == null && imageError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'imageUrl': _imageUrl,
      'linkUrl': _linkUrlController.text.trim().isEmpty
          ? null
          : _linkUrlController.text.trim(),
      'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
      'isActive': _isActive,
      'startsAt': _startsAt?.toIso8601String(),
      'endsAt': _endsAt?.toIso8601String(),
    };

    try {
      final repo = ref.read(bannersRepositoryProvider);
      if (!_isEditing) {
        await repo.createBanner(data);
      } else {
        await repo.updateBanner(widget.banner!['id'], data);
      }

      // Refresh the banners list.
      ref.invalidate(bannersProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final colors = context.colors;
    final initialDate =
        isStart ? _startsAt ?? DateTime.now() : _endsAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.primary,
              onPrimary: colors.onPrimary,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startsAt = picked;
        } else {
          _endsAt = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WDialog(
      title: _isEditing ? 'Edit Banner' : 'Create Banner',
      subtitle: _isEditing
          ? 'Update the details for this banner.'
          : 'Add a new promotional banner.',
      content: _buildForm(context),
      actions: [
        WButton(
          label: 'Cancel',
          variant: WButtonVariant.secondary,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        WButton(
          label: _isEditing ? 'Save Changes' : 'Create',
          isLoading: _isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner title (required).
        WTextInput(
          label: 'Banner Title',
          placeholder: 'e.g. Summer Sale',
          controller: _titleController,
          errorText: _titleError,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Banner image picker (required).
        MediaPickerWidget(
          label: 'Banner Image',
          currentImageUrl: _imageUrl,
          onImageSelected: (url) => setState(() {
            _imageUrl = url;
            _imageError = null;
          }),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            _imageError!,
            style: typography.style(
              size: TypographyTokens.xs,
              color: colors.error,
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.lg),

        // Link URL (optional).
        WTextInput(
          label: 'Link URL (Optional)',
          placeholder: 'https://...',
          controller: _linkUrlController,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Sort order.
        WTextInput(
          label: 'Sort Order',
          placeholder: '0',
          controller: _sortOrderController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Schedule.
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Start Date',
                value: _startsAt,
                onTap: () => _selectDate(context, true),
                onClear: () => setState(() => _startsAt = null),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: _DateField(
                label: 'End Date',
                value: _endsAt,
                onTap: () => _selectDate(context, false),
                onClear: () => setState(() => _endsAt = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Active status toggle.
        Row(
          children: [
            Switch(
              value: _isActive,
              activeThumbColor: colors.success,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Status',
                    style: typography.style(
                      size: TypographyTokens.sm,
                      weight: TypographyTokens.medium,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'If inactive, this banner will not be shown to customers.',
                    style: typography.style(
                      size: TypographyTokens.xs,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A token-styled date selector field used for the banner schedule. Renders a
/// label, the selected date (or a placeholder), a calendar icon, and a clear
/// button when a date is set.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: typography.style(
            size: TypographyTokens.sm,
            weight: TypographyTokens.medium,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        InkWell(
          onTap: onTap,
          borderRadius: RadiusTokens.borderRadiusMd,
          child: Container(
            height: WTextInput.height,
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: RadiusTokens.borderRadiusMd,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    hasValue
                        ? value!.toIso8601String().split('T').first
                        : 'Select date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.style(
                      size: TypographyTokens.base,
                      color: hasValue
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
