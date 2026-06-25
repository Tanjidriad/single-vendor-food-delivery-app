import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/menu_provider.dart';
import '../widgets/kitchen_header.dart';

class MenuAvailabilityView extends ConsumerWidget {
  const MenuAvailabilityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuProvider);

    return Column(
      children: [
        const KitchenHeader(
          title: 'Menu availability',
          subtitle: 'Toggle items in or out of stock',
        ),
        Expanded(
          child: menuState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pandaPink)),
            error: (e, st) => Center(child: Text('Error loading menu: $e', style: const TextStyle(color: AppColors.error))),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No menu items found.', style: TextStyle(color: AppColors.gray700)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isAvailable = item['isAvailable'] ?? true;
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        item['name'] ?? 'Item',
                        style: TextStyle(
                          color: isAvailable ? AppColors.black500 : AppColors.gray700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isAvailable ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        item['category']?['name'] ?? 'General',
                        style: const TextStyle(color: AppColors.gray700, fontSize: 13),
                      ),
                      trailing: Switch(
                        value: isAvailable,
                        activeColor: AppColors.white50,
                        activeTrackColor: AppColors.success,
                        inactiveThumbColor: AppColors.white50,
                        inactiveTrackColor: AppColors.gray400,
                        onChanged: (val) {
                          ref.read(menuProvider.notifier).toggleItemAvailability(item['id'], val);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
