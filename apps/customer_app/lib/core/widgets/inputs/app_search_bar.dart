import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Figma 215:1135 — Alt search bar (white pill + shadow) vs gray pill (promo / inline).
enum AppSearchBarStyle {
  /// White 48px pill, shadow, search + divider + filter (home hub).
  uberAlt,

  /// Gray #EEE fill, full pill, search icon (in-screen search).
  uberGrayPill,

  /// Bordered surface pill (legacy / subtle).
  bordered,
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hint,
    this.onTap,
    this.readOnly = true,
    this.controller,
    this.onChanged,
    this.style = AppSearchBarStyle.uberAlt,
    this.onFilterTap,
  });

  final String? hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final AppSearchBarStyle style;
  final VoidCallback? onFilterTap;

  String get _effectiveHint {
    if (hint != null) return hint!;
    switch (style) {
      case AppSearchBarStyle.uberAlt:
        return 'What are you craving?';
      default:
        return 'Search dishes...';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppSearchBarStyle.uberAlt:
        return _UberAltBar(
          hint: _effectiveHint,
          onTap: onTap,
          readOnly: readOnly,
          controller: controller,
          onChanged: onChanged,
          onFilterTap: onFilterTap,
        );
      case AppSearchBarStyle.uberGrayPill:
        return _UberGrayPill(
          hint: _effectiveHint,
          onTap: onTap,
          readOnly: readOnly,
          controller: controller,
          onChanged: onChanged,
        );
      case AppSearchBarStyle.bordered:
        return _BorderedBar(
          hint: _effectiveHint,
          onTap: onTap,
          readOnly: readOnly,
          controller: controller,
          onChanged: onChanged,
        );
    }
  }
}

class _UberAltBar extends StatelessWidget {
  const _UberAltBar({
    required this.hint,
    this.onTap,
    required this.readOnly,
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(48),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(48),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(48),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(AppIcons.search, size: 22, color: AppColors.black500),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly && onTap != null,
                    onChanged: onChanged,
                    onTap: onTap,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.black300,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.black300,
                            fontSize: 16,
                            height: 24 / 16,
                          ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.gray600,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
                  icon: const Icon(AppIcons.filter, size: 22, color: AppColors.black500),
                  onPressed: onFilterTap ?? () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UberGrayPill extends StatelessWidget {
  const _UberGrayPill({
    required this.hint,
    this.onTap,
    required this.readOnly,
    this.controller,
    this.onChanged,
  });

  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(AppIcons.search, size: 22, color: AppColors.black500),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly && onTap != null,
                  onChanged: onChanged,
                  onTap: onTap,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 20 / 16,
                      ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 20 / 16,
                        ),
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

class _BorderedBar extends StatelessWidget {
  const _BorderedBar({
    required this.hint,
    this.onTap,
    required this.readOnly,
    this.controller,
    this.onChanged,
  });

  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.search, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly && onTap != null,
                  onChanged: onChanged,
                  onTap: onTap,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDisabled,
                        ),
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
