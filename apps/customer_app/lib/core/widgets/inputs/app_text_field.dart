import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Uber Eats–style text field (Figma node 215:1135): #EEE fill, 2px black focus, 50px height.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  /// When true with [obscureText], shows an eye toggle (password field).
  final bool showObscureToggle;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && !widget.showObscureToggle) {
      _hidden = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveObscure = widget.showObscureToggle ? _hidden : widget.obscureText;

    Widget? suffix = widget.suffixIcon;
    if (widget.showObscureToggle && widget.obscureText) {
      suffix = IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(
          _hidden ? AppIcons.eye : AppIcons.eyeOff,
          size: 22,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: effectiveObscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            height: 24 / 16,
          ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: suffix,
        isDense: true,
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inputPlaceholder,
              height: 24 / 16,
            ),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
