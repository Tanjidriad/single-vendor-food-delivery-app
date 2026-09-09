import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../profile/presentation/providers/checkout_address_provider.dart';

/// Full-screen "we don't deliver here yet" state, shown on the discovery tabs
/// when the customer's selected address is outside every active delivery zone.
/// Mirrors the Foodpanda / Uber Eats address-gate experience.
class ZoneTakeover extends ConsumerWidget {
  const ZoneTakeover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(checkoutAddressProvider);
    final addressLine = _formatAddress(address);

    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/illustrations/onboarding_delivery.svg',
                  width: 240,
                  height: 200,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 32),
                Text(
                  "We're not in your area yet",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 12),
                Text(
                  "We don't deliver to your selected address yet. "
                  'Try a different address to see the menu and order.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                if (addressLine != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            addressLine,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: 280,
                  child: AppButton(
                    label: 'Change address',
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                    onPressed: () =>
                        context.push('${RoutePaths.addresses}?select=true'),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return null;
    final label = address['label'] as String?;
    final line1 = address['line1'] as String? ?? '';
    final city = address['city'] as String?;
    final location = city != null && city.isNotEmpty ? '$line1, $city' : line1;
    if (location.isEmpty) return label;
    return label != null && label.isNotEmpty ? '$label • $location' : location;
  }
}
