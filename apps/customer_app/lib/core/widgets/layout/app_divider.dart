import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.inset = false});

  final bool inset;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: inset ? AppSpacing.md : 0,
      endIndent: inset ? AppSpacing.md : 0,
    );
  }
}
