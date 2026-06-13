import 'package:flutter/material.dart';

import '../../../core/widgets/commerce/premium_menu_item_card.dart';

class PremiumMenuItemListSample extends StatelessWidget {
  const PremiumMenuItemListSample({super.key});

  static const _items = [
    PremiumMenuItemCardData(
      id: 'classic-burger',
      name: 'Classic Burger',
      description: 'Beef patty, cheddar, pickles, lettuce, and house sauce.',
      price: 350,
      discountedPrice: 299,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
      dietType: MenuItemDietType.nonVeg,
      badge: 'Bestseller',
      isCustomizable: true,
      rating: 4.8,
      ratingCount: 214,
      highlightLabel: 'Most Loved',
    ),
    PremiumMenuItemCardData(
      id: 'margherita-pizza',
      name: 'Margherita Pizza',
      description: 'Fresh mozzarella, tomato sauce, basil, and olive oil.',
      price: 550,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
      dietType: MenuItemDietType.veg,
      badge: 'Popular',
      rating: 4.6,
      ratingCount: 149,
    ),
    PremiumMenuItemCardData(
      id: 'tonkotsu-ramen',
      name: 'Tonkotsu Ramen',
      description: 'Rich broth, noodles, marinated egg, and spring onion.',
      price: 390,
      imageUrl:
          'https://images.unsplash.com/photo-1612929631298-494d32d0e8a2?w=800&q=80',
      dietType: MenuItemDietType.nonVeg,
      isCustomizable: true,
      highlightLabel: 'Chef Pick',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: _items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, itemIndex) => PremiumMenuItemCard(
                data: _items[itemIndex],
                variant: PremiumMenuItemCardVariant.compact,
                width: MediaQuery.sizeOf(context).width * 0.82,
                onTap: () {},
                onCustomize: () {},
              ),
            ),
          );
        }

        return PremiumMenuItemCard(
          data: _items[index - 1],
          onTap: () {},
          onCustomize: () {},
        );
      },
    );
  }
}
