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
    return Text(
      title,
      style: compact
          ? Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)
          : Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
