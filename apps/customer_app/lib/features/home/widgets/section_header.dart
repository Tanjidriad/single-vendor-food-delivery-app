import 'package:flutter/material.dart';

import '../../../core/widgets/texts/app_section_heading.dart';

/// Section title row — delegates to [AppSectionHeading] with standard 20px padding.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action = 'see all',
    this.onAction,
    this.topPadding = 16,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 14),
      child: AppSectionHeading(
        title: title,
        actionLabel: action ?? 'see all',
        showAction: onAction != null,
        onAction: onAction,
      ),
    );
  }
}
