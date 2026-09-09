import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Standard shell for bottom-nav tab screens.
class RiderTabScaffold extends StatelessWidget {
  const RiderTabScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = body;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: actions,
      ),
      body: onRefresh != null
          ? RefreshIndicator(
              onRefresh: onRefresh!,
              child: content,
            )
          : content,
    );
  }
}
