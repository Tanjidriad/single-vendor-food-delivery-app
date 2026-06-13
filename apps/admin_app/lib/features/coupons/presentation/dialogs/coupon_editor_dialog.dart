import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/tokens/app_tokens.dart';
import '../../../../core/widgets/w_button.dart';
import '../../../../core/widgets/w_dialog.dart';
import '../../../../core/widgets/w_select_input.dart';
import '../../../../core/widgets/w_text_input.dart';
import '../../data/coupons_repository.dart';

/// Create / Edit coupon dialog (Requirements 12.2, 12.4).
///
/// Presentational redesign of the coupon editor built on the standardized
/// component library: [WDialog] for the modal chrome, [WTextInput] /
/// [WSelectInput] for fields with inline validation errors, date-picker
/// buttons for the valid period, and [WButton] for the footer actions. The
/// data layer, Riverpod providers, and create / update flows are preserved
/// unchanged.
class CouponEditorDialog extends ConsumerStatefulWidget {
  /// The existing coupon map when editing, or `null` when creating a new one.
  final Map<String, dynamic>? coupon;

  const CouponEditorDialog({super.key, this.coupon});

  @override
  ConsumerState<CouponEditorDialog> createState() =>
      _CouponEditorDialogState();
}

class _CouponEditorDialogState extends ConsumerState<CouponEditorDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _usageLimitController;

  String _discountType = 'PERCENTAGE';
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isLoading = false;

  // Inline validation errors.
  String? _codeError;
  String? _discountValueError;
  String? _dateError;

  bool get _isEditing => widget.coupon != null;

  static const List<SelectOption> _discountTypeOptions = [
    SelectOption(value: 'PERCENTAGE', label: 'Percentage %'),
    SelectOption(value: 'FLAT', label: 'Flat Amount \$'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeController = TextEditingController(text: c?['code'] ?? '');
    _discountValueController = TextEditingController(
      text: (c?['discountValue'] ?? '').toString(),
    );
    _minOrderController = TextEditingController(
      text: (c?['minOrderAmount'] ?? '').toString(),
    );
    _maxDiscountController = TextEditingController(
      text: (c?['maxDiscountAmount'] ?? '').toString(),
    );
    _usageLimitController = TextEditingController(
      text: (c?['usageLimit'] ?? '').toString(),
    );

    _discountType = c?['discountType'] ?? 'PERCENTAGE';
    _isActive = c?['isActive'] ?? true;
    _validFrom =
        c?['validFrom'] != null ? DateTime.tryParse(c!['validFrom']) : null;
    _validUntil =
        c?['validUntil'] != null ? DateTime.tryParse(c!['validUntil']) : null;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  /// Validates required fields and the date range, populating inline errors.
  /// Returns `true` when the form may be submitted.
  bool _validate() {
    String? codeError;
    String? discountValueError;
    String? dateError;

    if (_codeController.text.trim().isEmpty) {
      codeError = 'Coupon code is required';
    }
    final valueText = _discountValueController.text.trim();
    if (valueText.isEmpty) {
      discountValueError = 'Discount value is required';
    } else if (double.tryParse(valueText) == null) {
      discountValueError = 'Enter a valid number';
    }
    if (_validFrom == null || _validUntil == null) {
      dateError = 'Select both a start and end date';
    }

    setState(() {
      _codeError = codeError;
      _discountValueError = discountValueError;
      _dateError = dateError;
    });

    return codeError == null &&
        discountValueError == null &&
        dateError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'discountType': _discountType,
      'discountValue': double.tryParse(_discountValueController.text) ?? 0,
      'minOrderAmount': double.tryParse(_minOrderController.text),
      'maxDiscountAmount': double.tryParse(_maxDiscountController.text),
      'usageLimit': int.tryParse(_usageLimitController.text),
      'isActive': _isActive,
      'validFrom': _validFrom?.toIso8601String(),
      'validUntil': _validUntil?.toIso8601String(),
    };

    try {
      final repo = ref.read(couponsRepositoryProvider);
      if (!_isEditing) {
        await repo.createCoupon(data);
      } else {
        await repo.updateCoupon(widget.coupon!['id'], data);
      }

      ref.invalidate(couponsProvider);

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

  Future<void> _selectDate(bool isStart) async {
    final colors = context.colors;
    final initialDate =
        isStart ? _validFrom ?? DateTime.now() : _validUntil ?? DateTime.now();
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
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
        _dateError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WDialog(
      title: _isEditing ? 'Edit Coupon' : 'Create Coupon',
      subtitle: _isEditing
          ? 'Update the details for this coupon.'
          : 'Create a new promotional discount code.',
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
    final isPercentage = _discountType == 'PERCENTAGE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coupon code (required).
        WTextInput(
          label: 'Coupon Code',
          placeholder: 'e.g. SUMMER50',
          controller: _codeController,
          errorText: _codeError,
          onChanged: (_) {
            if (_codeError != null) setState(() => _codeError = null);
          },
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Discount type + value.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WSelectInput(
                label: 'Type',
                options: _discountTypeOptions,
                value: _discountTypeOptions.firstWhere(
                  (o) => o.value == _discountType,
                  orElse: () => _discountTypeOptions.first,
                ),
                onChanged: (option) =>
                    setState(() => _discountType = option.value),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: WTextInput(
                label: 'Value',
                placeholder: isPercentage ? 'e.g. 20' : 'e.g. 5.00',
                controller: _discountValueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                errorText: _discountValueError,
                onChanged: (_) {
                  if (_discountValueError != null) {
                    setState(() => _discountValueError = null);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Min order + max discount.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WTextInput(
                label: 'Min Order \$ (Optional)',
                placeholder: '0.00',
                controller: _minOrderController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: WTextInput(
                label: 'Max Discount \$ (Optional)',
                placeholder: '0.00',
                controller: _maxDiscountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                disabled: !isPercentage,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Usage limit.
        WTextInput(
          label: 'Total Usage Limit (Optional)',
          placeholder: 'Unlimited',
          controller: _usageLimitController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // Valid period.
        _buildDateRangeField(context),
        const SizedBox(height: SpacingTokens.lg),

        // Active toggle.
        _LabeledSwitch(
          label: 'Active',
          subtitle: 'If inactive, customers cannot apply this code.',
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
        ),
      ],
    );
  }

  Widget _buildDateRangeField(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final hasError = _dateError != null && _dateError!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Valid Period',
          style: typography.style(
            size: TypographyTokens.sm,
            weight: TypographyTokens.medium,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Row(
          children: [
            Expanded(
              child: _DatePickerButton(
                icon: Icons.calendar_today_outlined,
                label: _validFrom == null
                    ? 'Valid From'
                    : _formatDate(_validFrom!),
                isPlaceholder: _validFrom == null,
                onPressed: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: _DatePickerButton(
                icon: Icons.event_outlined,
                label: _validUntil == null
                    ? 'Valid Until'
                    : _formatDate(_validUntil!),
                isPlaceholder: _validUntil == null,
                onPressed: () => _selectDate(false),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            _dateError!,
            style: typography.style(
              size: TypographyTokens.xs,
              color: colors.error,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) =>
      date.toIso8601String().split('T').first;
}

/// A token-styled date-picker trigger matching the height and border treatment
/// of [WTextInput].
class _DatePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPlaceholder;
  final VoidCallback onPressed;

  const _DatePickerButton({
    required this.icon,
    required this.label,
    required this.isPlaceholder,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Material(
      color: colors.surface,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: InkWell(
        onTap: onPressed,
        borderRadius: RadiusTokens.borderRadiusMd,
        child: Container(
          height: WTextInput.height,
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.borderRadiusMd,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.style(
                    size: TypographyTokens.base,
                    color: isPlaceholder
                        ? colors.textSecondary
                        : colors.textPrimary,
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

/// A compact labeled switch with an optional subtitle, consuming design tokens.
class _LabeledSwitch extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Row(
      children: [
        Expanded(
          child: Column(
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
              if (subtitle != null) ...[
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  subtitle!,
                  style: typography.style(
                    size: TypographyTokens.xs,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: colors.success,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
