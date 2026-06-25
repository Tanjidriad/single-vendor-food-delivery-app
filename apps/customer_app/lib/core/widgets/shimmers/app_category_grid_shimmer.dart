import 'package:flutter/material.dart';

import '../../utils/responsive/app_responsive.dart';
import 'app_shimmer_effect.dart';

/// Home category grid placeholder (CWT-style blocks).
class AppCategoryGridShimmer extends StatelessWidget {
  const AppCategoryGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = AppResponsive.homeCategoryColumns(context);
    final tileSize = AppResponsive.homeCategoryTileSize(context);
    final padding = AppResponsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: columns * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: tileSize / (tileSize + 28),
        ),
        itemBuilder: (_, _) => Column(
          children: [
            AppShimmerEffect(width: tileSize, height: tileSize, radius: 16),
            const SizedBox(height: 8),
            AppShimmerEffect(width: tileSize * 0.75, height: 10, radius: 4),
          ],
        ),
      ),
    );
  }
}
