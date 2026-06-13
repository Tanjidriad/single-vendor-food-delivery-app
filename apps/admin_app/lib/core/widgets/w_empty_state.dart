import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';
import 'w_button.dart';

/// A composed UI shown when a data list or view contains zero items.
///
/// Renders (Requirement 15.5):
/// - an illustrative [icon] (48px),
/// - a [title] identifying the entity type with no results
///   (e.g. "No orders found"),
/// - an optional [subtitle] suggesting a next step (text sm, secondary color),
/// - an optional action button shown when both [actionLabel] and [onAction]
///   are provided.
class WEmptyState extends StatelessWidget {
  /// The illustrative icon rendered at [iconSize]. Defaults to an inbox glyph.
  final IconData? icon;

  /// The primary message identifying the empty condition.
  final String title;

  /// Optional supporting text suggesting a next step or explaining the empty
  /// condition.
  final String? subtitle;

  /// Optional action button label. The button is rendered only when both this
  /// and [onAction] are provided.
  final String? actionLabel;

  /// Optional callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  const WEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Illustrative icon size in logical pixels (Requirement 15.5).
  static const double iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final hasAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: iconSize,
              color: colors.gray400,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tokens.typography.style(
                size: TypographyTokens.md,
                weight: TypographyTokens.semibold,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: tokens.typography.style(
                  size: TypographyTokens.sm,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: SpacingTokens.lg),
              WButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
