import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// A CWT-style page header with breadcrumb navigation and a large heading.
class BreadcrumbsWithHeading extends StatelessWidget {
  final String heading;
  final List<String> breadcrumbItems;
  final Widget? trailing;

  const BreadcrumbsWithHeading({
    super.key,
    required this.heading,
    required this.breadcrumbItems,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                for (int i = 0; i < breadcrumbItems.length; i++) ...[
                  if (i > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                    ),
                  ],
                  Text(
                    breadcrumbItems[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: i == breadcrumbItems.length - 1
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: i == breadcrumbItems.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Heading
            Text(
              heading,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
