import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/device/device_utility.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/media/app_food_image.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../widgets/addon_tile.dart';
import '../../widgets/item_detail_skeleton.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Map<String, dynamic>? _item;
  int _qty = 1;
  final _notesController = TextEditingController();
  final Map<String, CartAddon> _selectedAddons = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(restaurantRepositoryProvider).getItem(widget.itemId);
      if (mounted) {
        setState(() {
          _item = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _calculatedTotal {
    if (_item == null) return 0;
    final basePrice = (_item!['price'] as num?)?.toDouble() ?? 0;
    double addonsPrice = 0;
    for (final addon in _selectedAddons.values) {
      addonsPrice += addon.price;
    }
    return (basePrice + addonsPrice) * _qty;
  }

  void _toggleAddon(String id, String name, double price) {
    DeviceUtils.vibrate();
    setState(() {
      if (_selectedAddons.containsKey(id)) {
        _selectedAddons.remove(id);
      } else {
        _selectedAddons[id] = CartAddon(addonId: id, name: name, price: price);
      }
    });
  }

  void _addToCart() {
    if (_item == null) return;
    DeviceUtils.vibrate();
    final price = (_item!['price'] as num?)?.toDouble() ?? 0;

    ref.read(cartProvider.notifier).addItem(CartItem(
          menuItemId: _item!['id'] as String,
          name: _item!['name'] as String? ?? '',
          unitPrice: price,
          quantity: _qty,
          imageUrl: _item!['imageUrl'] as String?,
          notes: _notesController.text.trim(),
          addons: _selectedAddons.values.toList(),
        ));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Added to cart', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1500),
      ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const ItemDetailSkeleton();
    if (_item == null) return _buildError(context);

    final item = _item!;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final addons = item['addons'] as List<dynamic>? ?? [];
    final description = item['description'] as String?;
    final title = item['name'] as String? ?? 'Item Details';
    final imageUrl = item['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HERO IMAGE APP BAR ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppFoodImage(
                    imageUrl: imageUrl,
                    placeholderSeed: title,
                    fit: BoxFit.cover,
                  ),
                  // Bottom gradient for smooth transition
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surface.withValues(alpha: 0),
                            AppColors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          AppFormatter.formatCurrency(price),
                          style: AppTypography.priceLarge().copyWith(
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],

                  // Add-ons Section
                  if (addons.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text(
                          'Extras',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'Optional',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...addons.map((raw) {
                      final link = raw as Map<String, dynamic>;
                      final addon = link['addon'] as Map<String, dynamic>? ?? link;
                      final id = addon['id'] as String;
                      final addonName = addon['name'] as String? ?? '';
                      final addonPrice = (addon['price'] as num?)?.toDouble() ?? 0;
                      final selected = _selectedAddons.containsKey(id);

                      return AddonTile(
                        name: addonName,
                        price: addonPrice,
                        selected: selected,
                        onTap: () => _toggleAddon(id, addonName, addonPrice),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'Special Instructions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _notesController,
                    hint: 'e.g. No onions, extra spicy...',
                    maxLines: 3,
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── STICKY BOTTOM BAR ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            // Quantity Pill
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      DeviceUtils.vibrate();
                      setState(() => _qty = (_qty - 1).clamp(1, 99));
                    },
                    icon: Icon(Iconsax.minus, color: _qty > 1 ? AppColors.textPrimary : AppColors.textDisabled),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      DeviceUtils.vibrate();
                      setState(() => _qty = (_qty + 1).clamp(1, 99));
                    },
                    icon: const Icon(Iconsax.add, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Dynamic Add to Cart Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: AppButton(
                  label: 'Add • ${AppFormatter.formatCurrency(_calculatedTotal)}',
                  onPressed: _addToCart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Failed to load item details.'),
      ),
    );
  }
}
