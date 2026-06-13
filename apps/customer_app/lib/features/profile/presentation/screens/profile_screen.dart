import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cwt/cwt_header_container.dart';
import '../../../../core/widgets/cwt/cwt_section_heading.dart';
import '../../../../core/widgets/cwt/cwt_settings_menu_tile.dart';
import '../../../../core/widgets/cwt/cwt_user_profile_tile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header
            CwtPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// AppBar
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'Account',
                      style: Theme.of(context).textTheme.headlineMedium?.apply(color: Colors.white),
                    ),
                  ),

                  /// User Profile Card
                  CwtUserProfileTile(
                    onPressed: () => context.push(RoutePaths.editProfile),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            /// -- Profile Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -- Account Settings
                  const CwtSectionHeading(title: 'Account Settings', showActionButton: false),
                  const SizedBox(height: 16),

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

                  /// -- App Settings
                  const SizedBox(height: 32),
                  const CwtSectionHeading(title: 'App Settings', showActionButton: false),
                  const SizedBox(height: 16),

                  CwtSettingsMenuTile(
                    icon: Iconsax.location,
                    title: 'Geolocation',
                    subTitle: 'Set recommendation based on location',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  CwtSettingsMenuTile(
                    icon: Iconsax.security_user,
                    title: 'Safe Mode',
                    subTitle: 'Search result is safe for all ages',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: AppColors.primary,
                    ),
                  ),

                  /// -- Logout Button
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
                        await ref.read(authSessionProvider.notifier).logout();
                        if (context.mounted) context.go(RoutePaths.login);
                      },
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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
