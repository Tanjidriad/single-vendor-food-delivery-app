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
    final text = AppFormatter.formatCurrency(price);
    final base = isLarge
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.titleMedium;

    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: base?.copyWith(
        fontWeight: FontWeight.w700,
        decoration: lineThrough ? TextDecoration.lineThrough : null,
        color: lineThrough ? Theme.of(context).textTheme.bodySmall?.color : null,
      ),
    );
  }
}
