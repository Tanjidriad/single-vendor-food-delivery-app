import 'package:flutter/material.dart';

import '../../domain/entities/cart_item.dart';
import 'premium_cart_item_card.dart';

class PremiumCartItemListSample extends StatelessWidget {
  const PremiumCartItemListSample({super.key});

  static const _items = [
    CartItem(
      menuItemId: 'classic-burger',
      name: 'Classic Burger',
      unitPrice: 299,
      quantity: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
      notes: 'No onion',
      addons: [
        CartAddon(addonId: 'cheese', name: 'Extra Cheese', price: 50),
        CartAddon(addonId: 'sauce', name: 'Smoky Sauce', price: 20),
      ],
    ),
    CartItem(
      menuItemId: 'margherita-pizza',
      name: 'Margherita Pizza',
      unitPrice: 550,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
      notes: 'Medium spice',
    ),
    CartItem(
      menuItemId: 'iced-coffee',
      name: 'Iced Caramel Coffee',
      unitPrice: 180,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=800&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => PremiumCartItemCard(
        item: _items[index],
      ),
    );
  }
}
