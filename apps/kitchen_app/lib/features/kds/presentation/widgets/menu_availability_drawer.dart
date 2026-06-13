import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MenuAvailabilityDrawer extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const MenuAvailabilityDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<MenuAvailabilityDrawer> createState() => _MenuAvailabilityDrawerState();
}

class _MenuAvailabilityDrawerState extends State<MenuAvailabilityDrawer> {
  // Mock data for 86 list since we don't have an endpoint for it yet
  final List<Map<String, dynamic>> _menuItems = [
    {'id': '1', 'name': 'Classic Cheeseburger', 'category': 'Burgers', 'isAvailable': true},
    {'id': '2', 'name': 'Double Bacon Burger', 'category': 'Burgers', 'isAvailable': true},
    {'id': '3', 'name': 'Spicy Chicken Burger', 'category': 'Burgers', 'isAvailable': false},
    {'id': '4', 'name': 'Sweet Potato Fries', 'category': 'Sides', 'isAvailable': false},
    {'id': '5', 'name': 'Large Fries', 'category': 'Sides', 'isAvailable': true},
    {'id': '6', 'name': 'Vanilla Shake', 'category': 'Drinks', 'isAvailable': true},
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Container(
      width: 350,
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '86 List (Menu)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _menuItems.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(
                    item['name'],
                    style: TextStyle(
                      color: item['isAvailable'] ? AppColors.textPrimary : AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                      decoration: item['isAvailable'] ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    item['category'],
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Switch(
                    value: item['isAvailable'],
                    activeColor: AppColors.success,
                    inactiveThumbColor: AppColors.textDisabled,
                    inactiveTrackColor: AppColors.borderStrong,
                    onChanged: (val) {
                      setState(() {
                        item['isAvailable'] = val;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
