import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/inputs/media_picker_widget.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_select_input.dart';
import '../../../../core/widgets/w_text_input.dart';
import '../../data/menu_repository.dart';

/// Add / Edit menu item dialog (Requirements 9.4, 9.5, 9.7).
///
/// Presentational redesign of the menu item editor built on the standardized
/// component library: [WDialog] for the modal chrome, [WTextInput] /
/// [WSelectInput] for fields with inline validation errors, and [WButton] for
/// the footer actions. The data layer, Riverpod providers, and create / update
/// / add-on linking flows are preserved unchanged.
class MenuItemEditorDialog extends ConsumerStatefulWidget {
  /// The existing item map when editing, or `null` when adding a new item.
  final dynamic item;

  const MenuItemEditorDialog({super.key, this.item});

  @override
  ConsumerState<MenuItemEditorDialog> createState() =>
      _MenuItemEditorDialogState();
}

class _MenuItemEditorDialogState extends ConsumerState<MenuItemEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _compareAtPriceController;
  late final TextEditingController _tagsController;

  String _imageUrl = '';
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  String? _selectedCategoryId;
  final Set<String> _selectedAddonIds = {};
  final Set<String> _initialAddonIds = {};

  // Inline validation errors (Requirement 9.7).
  String? _nameError;
  String? _categoryError;
  String? _priceError;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?['name'] ?? '');
    _descController = TextEditingController(text: item?['description'] ?? '');
    _priceController =
        TextEditingController(text: item?['price']?.toString() ?? '');
    _compareAtPriceController = TextEditingController(
        text: item?['compareAtPrice']?.toString() ?? '');
    _tagsController = TextEditingController(
        text: (item?['tags'] as List<dynamic>?)?.join(', ') ?? '');
    _imageUrl = item?['imageUrl'] ?? '';
    _isAvailable = item?['isAvailable'] ?? true;
    _isFeatured = item?['isFeatured'] ?? false;
    _selectedCategoryId = item?['categoryId'];

    final addonsList = item?['addons'] as List<dynamic>? ?? [];
    for (final relation in addonsList) {
      final addonData = relation['addon'];
      if (addonData != null) {
        _selectedAddonIds.add(addonData['id']);
        _initialAddonIds.add(addonData['id']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// Validates the required fields (name, category, price) and populates the
  /// inline error strings. Returns `true` when the form may be submitted
  /// (Requirement 9.7).
  bool _validate() {
    String? nameError;
    String? categoryError;
    String? priceError;

    if (_nameController.text.trim().isEmpty) {
      nameError = 'Name is required';
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      categoryError = 'Category is required';
    }
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      priceError = 'Price is required';
    } else if (double.tryParse(priceText) == null) {
      priceError = 'Enter a valid price';
    }

    setState(() {
      _nameError = nameError;
      _categoryError = categoryError;
      _priceError = priceError;
    });

    return nameError == null && categoryError == null && priceError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(menuRepositoryProvider);

      final tagsList = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'compareAtPrice': double.tryParse(_compareAtPriceController.text),
        'tags': tagsList,
        'imageUrl': _imageUrl.isNotEmpty ? _imageUrl : null,
        'isAvailable': _isAvailable,
        'isFeatured': _isFeatured,
        'categoryId': _selectedCategoryId,
      };

      if (!_isEditing) {
        final res = await repo.createItem(data);
        final newItemId = res['id'];
        for (final addonId in _selectedAddonIds) {
          try {
            await repo.linkAddon(newItemId, addonId);
          } catch (_) {}
        }
      } else {
        final itemId = widget.item['id'];
        await repo.updateItem(itemId, data);

        final added = _selectedAddonIds.difference(_initialAddonIds);
        for (final addonId in added) {
          try {
            await repo.linkAddon(itemId, addonId);
          } catch (_) {}
        }

        final removed = _initialAddonIds.difference(_selectedAddonIds);
        for (final addonId in removed) {
          try {
            await repo.unlinkAddon(itemId, addonId);
          } catch (_) {}
        }
      }

      // Refresh the menu list.
      ref.invalidate(menuItemsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
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

  @override
  Widget build(BuildContext context) {
    return WDialog(
      title: _isEditing ? 'Edit Menu Item' : 'Add Menu Item',
      subtitle: _isEditing
          ? 'Update the details for this menu item.'
          : 'Create a new item for your menu.',
      content: _buildForm(context),
      actions: [
        WButton(
          label: 'Cancel',
          variant: WButtonVariant.secondary,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        WButton(
          label: _isEditing ? 'Save Changes' : 'Create Item',
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
        // Product image picker.
        MediaPickerWidget(
          label: 'Product Image',
          currentImageUrl: _imageUrl,
          onImageSelected: (url) => setState(() => _imageUrl = url),
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Item name (required).
        WTextInput(
          label: 'Item Name',
          placeholder: 'e.g. Spicy Ramen',
          controller: _nameController,
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Description.
        WTextInput(
          label: 'Description',
          placeholder: 'Short description of the item',
          controller: _descController,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Category dropdown (required).
        _buildCategoryField(),
        const SizedBox(height: SpacingTokens.lg),

        // Price + compare-at price.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WTextInput(
                label: 'Price',
                placeholder: '0.00',
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                errorText: _priceError,
                onChanged: (_) {
                  if (_priceError != null) setState(() => _priceError = null);
                },
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: WTextInput(
                label: 'Compare-at Price (Optional)',
                placeholder: '0.00',
                controller: _compareAtPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Tags.
        WTextInput(
          label: 'Tags (comma separated)',
          placeholder: 'e.g. Spicy, New Arrival',
          controller: _tagsController,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Availability + featured toggles.
        Row(
          children: [
            Expanded(
              child: _LabeledSwitch(
                label: 'Available',
                value: _isAvailable,
                activeColor: colors.success,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: _LabeledSwitch(
                label: 'Featured',
                value: _isFeatured,
                activeColor: colors.primary,
                onChanged: (val) => setState(() => _isFeatured = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Add-on selection.
        Text(
          'Add-ons',
          style: typography.style(
            size: TypographyTokens.sm,
            weight: TypographyTokens.medium,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        _buildAddonSelector(),
      ],
    );
  }

  Widget _buildCategoryField() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => WSelectInput(
        label: 'Category',
        options: const [],
        placeholder: 'Failed to load categories',
        errorText: 'Could not load categories',
      ),
      data: (categories) {
        // Auto-select the first category when none is chosen (add mode).
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategoryId == null) {
              setState(() => _selectedCategoryId = categories.first['id']);
            }
          });
        }

        final options = [
          for (final cat in categories)
            SelectOption(
              value: cat['id'] as String,
              label: cat['name'] as String,
            ),
        ];

        SelectOption? selected;
        for (final option in options) {
          if (option.value == _selectedCategoryId) selected = option;
        }

        return WSelectInput(
          label: 'Category',
          placeholder: 'Select a category',
          options: options,
          value: selected,
          errorText: _categoryError,
          onChanged: (option) => setState(() {
            _selectedCategoryId = option.value;
            _categoryError = null;
          }),
        );
      },
    );
  }

  Widget _buildAddonSelector() {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final addonsAsync = ref.watch(addonsProvider);

    return addonsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(SpacingTokens.sm),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, st) => Text(
        'Failed to load add-ons',
        style: typography.style(
          size: TypographyTokens.sm,
          color: colors.error,
        ),
      ),
      data: (addons) {
        if (addons.isEmpty) {
          return Text(
            'No add-ons created yet.',
            style: typography.style(
              size: TypographyTokens.sm,
              color: colors.textSecondary,
            ),
          );
        }
        return Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: [
            for (final addon in addons)
              FilterChip(
                label: Text('${addon['name']} (+\$${addon['price']})'),
                selected: _selectedAddonIds.contains(addon['id']),
                selectedColor: colors.primary.withValues(alpha: 0.12),
                checkmarkColor: colors.primary,
                side: BorderSide(color: colors.border),
                labelStyle: typography.style(
                  size: TypographyTokens.sm,
                  color: colors.textPrimary,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAddonIds.add(addon['id']);
                    } else {
                      _selectedAddonIds.remove(addon['id']);
                    }
                  });
                },
              ),
          ],
        );
      },
    );
  }
}

/// A compact labeled switch consuming the design tokens, used for the
/// availability and featured toggles in the editor form.
class _LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
        const SizedBox(width: SpacingTokens.sm),
        Flexible(
          child: Text(
            label,
            style: typography.style(
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
