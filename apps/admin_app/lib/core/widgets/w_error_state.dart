import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';
import 'w_button.dart';

/// A composed UI shown when a data fetch or operation fails.
///
/// Renders (Requirement 15.3):
/// - an error icon (24px, error color),
/// - a fixed title "Something went wrong",
/// - a user-friendly [message] (text sm, secondary color, truncated to
///   [maxMessageLength] characters with an ellipsis),
/// - a "Retry" button using the secondary button variant.
///
/// The [onRetry] callback is invoked when the retry button is pressed
/// (Requirement 15.4). Raw error strings, stack traces, or exception type
/// names must never be passed as [message] (Requirement 15.6); callers should
/// supply a friendly, human-readable description.
class WErrorState extends StatelessWidget {
  /// A user-friendly error description. Truncated to [maxMessageLength]
  /// characters with an ellipsis when longer. When `null` or empty, only the
  /// title is shown.
  final String? message;

  /// Invoked when the "Retry" button is pressed. When `null`, the retry button
  /// is disabled.
  final VoidCallback? onRetry;

  const WErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  /// Fixed title displayed above the message.
  static const String title = 'Something went wrong';

  /// Maximum number of characters displayed for [message] before truncation.
  static const int maxMessageLength = 150;

  /// Error icon size in logical pixels (Requirement 15.3).
  static const double iconSize = 24;

  /// Truncates [message] to [maxMessageLength] characters, appending an
  /// ellipsis when it exceeds that length.
  static String? formatMessage(String? message) {
    if (message == null) return null;
    if (message.length > maxMessageLength) {
      return '${message.substring(0, maxMessageLength)}…';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = tokens.colors;
    final displayMessage = formatMessage(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: colors.error,
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tokens.typography.style(
                size: TypographyTokens.md,
                weight: TypographyTokens.semibold,
                color: colors.textPrimary,
              ),
            ),
            if (displayMessage != null && displayMessage.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tokens.typography.style(
                  size: TypographyTokens.sm,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: SpacingTokens.lg),
            WButton(
              label: 'Retry',
              variant: WButtonVariant.secondary,
              leadingIcon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
