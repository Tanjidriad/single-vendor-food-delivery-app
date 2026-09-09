import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'skeleton_box.dart';

class MenuSkeleton extends StatelessWidget {
  const MenuSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const Row(
        children: [
          SkeletonBox(width: 88, height: 88, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 60, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
