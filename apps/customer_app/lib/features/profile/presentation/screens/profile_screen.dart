import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cwt/cwt_section_heading.dart';
import '../../../../core/widgets/cwt/cwt_settings_menu_tile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final initial =
        (user?.fullName ?? user?.email ?? 'U').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Profile Header ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Account',
                          style: textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              initial,
                              style: textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'User',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? '',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.push(RoutePaths.editProfile),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                            ),
                            icon: Icon(Iconsax.edit,
                                size: 20, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Settings ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CwtSectionHeading(
                      title: 'Account Settings', showActionButton: false),
                  const SizedBox(height: 16),

                  ...[
                    CwtSettingsMenuTile(
                      icon: Iconsax.safe_home,
                      title: 'My Addresses',
                      subTitle: 'Set shopping delivery address',
                      onTap: () => context.push(RoutePaths.addresses),
                    ),
                    CwtSettingsMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: 'My Cart',
                      subTitle: 'Add, remove products and move to checkout',
                      onTap: () => context.push(RoutePaths.cart),
                    ),
                    CwtSettingsMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'My Orders',
                      subTitle: 'In-progress and Completed Orders',
                      onTap: () => context.push(RoutePaths.orders),
                    ),
                    CwtSettingsMenuTile(
                      icon: Iconsax.discount_shape,
                      title: 'My Offers',
                      subTitle: 'List of all the discounted coupons',
                      onTap: () => context.push(RoutePaths.offers),
                    ),
                    CwtSettingsMenuTile(
                      icon: Iconsax.notification,
                      title: 'Notifications',
                      subTitle: 'Set any kind of notification message',
                      onTap: () => context.push(RoutePaths.notifications),
                    ),
                    CwtSettingsMenuTile(
                      icon: Iconsax.message_question,
                      title: 'Support',
                      subTitle: 'Chat with our support team',
                      onTap: () => context.push(RoutePaths.support),
                    ),
                  ].asMap().entries.map((e) => e.value
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 60 * e.key),
                        duration: 350.ms,
                      )
                      .slideX(
                        begin: 0.03,
                        end: 0,
                        delay: Duration(milliseconds: 60 * e.key),
                        duration: 350.ms,
                        curve: Curves.easeOut,
                      )),

                  const SizedBox(height: 32),
                  const CwtSectionHeading(
                      title: 'App Settings', showActionButton: false),
                  const SizedBox(height: 16),

                  CwtSettingsMenuTile(
                    icon: Iconsax.location,
                    title: 'Geolocation',
                    subTitle: 'Set recommendation based on location',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeTrackColor: AppColors.primary,
                    ),
                  ),
                  CwtSettingsMenuTile(
                    icon: Iconsax.security_user,
                    title: 'Safe Mode',
                    subTitle: 'Search result is safe for all ages',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeTrackColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () async {
                        await ref
                            .read(authSessionProvider.notifier)
                            .logout();
                        if (context.mounted) context.go(RoutePaths.login);
                      },
                      child: const Text('Logout',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
