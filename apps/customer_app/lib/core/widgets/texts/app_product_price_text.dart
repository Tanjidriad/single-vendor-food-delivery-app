import 'package:flutter/material.dart';

import '../../utils/formatters/formatter.dart';

/// CWT [TProductPriceText] with app currency formatting.
class AppProductPriceText extends StatelessWidget {
  const AppProductPriceText({
    super.key,
    required this.price,
    this.isLarge = false,
    this.maxLines = 1,
    this.lineThrough = false,
  });

  final double price;
  final int maxLines;
  final bool isLarge;
  final bool lineThrough;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppFormatter.formatCurrency(price);
    final base = isLarge
        ? theme.textTheme.headlineSmall
        : theme.textTheme.titleMedium;

    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: base?.copyWith(
        fontWeight: FontWeight.w700,
        decoration: lineThrough ? TextDecoration.lineThrough : null,
        // Theme-driven so prices stay readable in light and dark.
        color: lineThrough
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
