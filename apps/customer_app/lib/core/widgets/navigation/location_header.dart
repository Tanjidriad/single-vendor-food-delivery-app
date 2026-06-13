import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';

class LocationHeader extends StatelessWidget {
  const LocationHeader({
    super.key,
    this.address = 'Add delivery address',
    this.meta,
    this.onTap,
  });

  final String address;
  final String? meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(AppIcons.location, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    address,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta != null)
                    Text(meta!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(AppIcons.chevronDown, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
