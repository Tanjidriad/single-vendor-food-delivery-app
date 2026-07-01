import 'package:flutter/material.dart';

/// CWT [TProductTitleText].
class AppProductTitleText extends StatelessWidget {
  const AppProductTitleText({
    super.key,
    required this.title,
    this.compact = false,
    this.maxLines = 2,
    this.textAlign = TextAlign.left,
  });

  final String title;
  final bool compact;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = compact ? theme.textTheme.labelLarge : theme.textTheme.titleSmall;
    return Text(
      title,
      style: base?.copyWith(
        fontWeight: FontWeight.w600,
        // labelLarge is themed for buttons (onPrimary/white); force the on-surface
        // colour so titles stay readable on cards in both light and dark.
        color: theme.colorScheme.onSurface,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
