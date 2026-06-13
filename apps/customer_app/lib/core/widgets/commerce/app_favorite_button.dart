import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../icons/app_circular_icon.dart';

/// CWT [TFavouriteIcon] — Riverpod-backed wishlist toggle.
class AppFavoriteButton extends ConsumerWidget {
  const AppFavoriteButton({
    super.key,
    required this.menuItemId,
    this.size,
  });

  final String menuItemId;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteMenuItemIdsProvider);
    final isFavorite = favorites.valueOrNull?.contains(menuItemId) ?? false;

    return AppCircularIcon(
      width: size ?? 36,
      height: size ?? 36,
      size: 18,
      icon: isFavorite ? AppIcons.heartFilled : AppIcons.heart,
      color: isFavorite ? AppColors.error : AppColors.textPrimary,
      onPressed: favorites.isLoading
          ? null
          : () => ref.read(favoriteMenuItemIdsProvider.notifier).toggle(menuItemId),
    );
  }
}
