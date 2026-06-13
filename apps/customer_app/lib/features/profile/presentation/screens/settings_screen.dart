import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shapes/app_rounded_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppRoundedContainer(
            showBorder: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(AppIcons.notification),
                  title: const Text('Notifications'),
                  trailing: const Icon(AppIcons.chevronRight, size: 18),
                  onTap: () => context.push(RoutePaths.notifications),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(AppIcons.location),
                  title: const Text('Delivery addresses'),
                  trailing: const Icon(AppIcons.chevronRight, size: 18),
                  onTap: () => context.push(RoutePaths.addresses),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppRoundedContainer(
            showBorder: true,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Demo Kitchen customer app — v1.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
