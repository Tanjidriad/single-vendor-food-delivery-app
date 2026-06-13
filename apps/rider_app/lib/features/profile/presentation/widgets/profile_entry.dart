import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';

/// A circular avatar control rendered in the home header.
///
/// Tapping it opens the Rider profile view (Requirements 8.1, 8.2).
///
/// If [initials] are provided they are shown inside the avatar; otherwise a
/// generic person icon is used. The control is themed with [AppColors].
class ProfileEntry extends StatelessWidget {
  /// Optional initials (e.g. "RA") to display inside the avatar.
  ///
  /// When null/empty, a person icon is rendered instead. This keeps the
  /// control functional even when rider identity is not yet available.
  final String? initials;

  /// Diameter of the circular avatar.
  final double size;

  /// Optional tap override. Defaults to navigating to the profile route.
  ///
  /// Exposed primarily so widget tests can observe activation without a
  /// router, but production callers can rely on the default navigation.
  final VoidCallback? onTap;

  const ProfileEntry({
    super.key,
    this.initials,
    this.size = 44,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    // Req 8.2: open the Rider profile view.
    context.push(RoutePaths.profile);
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = initials?.trim();
    final hasInitials = trimmed != null && trimmed.isNotEmpty;

    return Semantics(
      button: true,
      label: 'Profile',
      child: InkWell(
        onTap: () => _handleTap(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: hasInitials
              ? Text(
                  trimmed.length > 2
                      ? trimmed.substring(0, 2).toUpperCase()
                      : trimmed.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.36,
                  ),
                )
              : Icon(
                  LucideIcons.user,
                  size: size * 0.5,
                  color: AppColors.textInverse,
                ),
        ),
      ),
    );
  }
}
