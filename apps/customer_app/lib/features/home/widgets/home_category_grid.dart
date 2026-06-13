import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive/app_responsive.dart';
import '../../../core/widgets/media/app_food_image.dart';

class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.onMoreTap,
  });

  final List<HomeCategoryItem> categories;
  final void Function(HomeCategoryItem item) onCategoryTap;
  final VoidCallback? onMoreTap;

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
        itemCount: categories.length.clamp(0, columns * 2),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: tileSize / (tileSize + 28),
        ),
        itemBuilder: (_, i) {
          final item = categories[i];
          return _CategoryCell(
            item: item,
            tileSize: tileSize,
            onTap: () {
              if (item.name == 'More') {
                onMoreTap?.call();
              } else {
                onCategoryTap(item);
              }
            },
          );
        },
      ),
    );
  }
}

class HomeCategoryItem {
  const HomeCategoryItem({this.id, required this.name, this.imageUrl});

  final String? id;
  final String name;
  final String? imageUrl;

  String get placeholderSeed => id ?? name.toLowerCase().replaceAll(' ', '-');
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.item,
    required this.tileSize,
    required this.onTap,
  });

  final HomeCategoryItem item;
  final double tileSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AppFoodImage(
              imageUrl: item.imageUrl,
              placeholderSeed: item.placeholderSeed,
              width: tileSize,
              height: tileSize,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

HomeCategoryItem categoryFromApi(Map<String, dynamic> c) {
  return HomeCategoryItem(
    id: c['id'] as String?,
    name: c['name'] as String? ?? 'Category',
    imageUrl: c['imageUrl'] as String?,
  );
}
