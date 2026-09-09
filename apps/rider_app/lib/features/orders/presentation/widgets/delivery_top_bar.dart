import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// The top overlay on the active-delivery map: a back control, a report-problem
/// action, and an optional ETA chip.
class DeliveryTopBar extends StatelessWidget {
  const DeliveryTopBar({
    super.key,
    required this.etaMinutes,
    required this.onReportProblem,
  });

  final int? etaMinutes;
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.go(RoutePaths.home),
            ),
            TextButton.icon(
              onPressed: onReportProblem,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.offline,
                backgroundColor: Colors.white,
              ),
              icon: const Icon(LucideIcons.triangleAlert, size: 18),
              label: const Text('Report'),
            ),
            if (etaMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.borderDark),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.navigation,
                      size: 16,
                      color: AppColors.inProgress,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$etaMinutes min away',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// A small circular icon button used in the top overlay.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}
