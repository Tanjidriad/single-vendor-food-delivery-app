import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/services/sunmi_print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool? _printerConnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrinter());
  }

  Future<void> _checkPrinter() async {
    final printer = ref.read(printServiceProvider);
    final ok = await printer.connect();
    if (mounted) setState(() => _printerConnected = ok);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final prefs = ref.watch(kitchenPreferencesProvider);
    final printerReady = _printerConnected == true;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.gray200)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.setting_2, color: AppColors.pandaPink, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _buildSectionHeader('Profile'),
                _buildCard([
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.pandaPinkLight,
                      child: Icon(Iconsax.user, color: AppColors.pandaPink),
                    ),
                    title: Text(user?['fullName'] ?? 'Kitchen Staff', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    subtitle: Text(user?['email'] ?? 'Kitchen account', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.gray700)),
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                // Hardware & Printing
                _buildSectionHeader('Hardware & Printing'),
                _buildCard([
                  _buildSwitchTile(
                    icon: Iconsax.printer,
                    title: 'Auto-print new orders',
                    subtitle: 'Automatically print KOT when an order is accepted',
                    value: prefs.autoPrint,
                    onChanged: (v) =>
                        ref.read(kitchenPreferencesProvider.notifier).setAutoPrint(v),
                  ),
                  const Divider(height: 1, color: AppColors.gray200),
                  ListTile(
                    leading: Icon(Iconsax.link, color: isDark ? AppColors.darkTextSecondary : AppColors.gray700),
                    title: Text('Sunmi Printer Status', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: printerReady ? AppColors.success : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          printerReady ? 'Ready' : 'Not detected',
                          style: TextStyle(
                            color: printerReady ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.gray500),
                      ],
                    ),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _checkPrinter();
                      if (!mounted) return;
                      final service = ref.read(printServiceProvider);
                      if (service is SunmiPrintService && service.isAvailable) {
                        await service.printKitchenTicket({
                          'orderNumber': 'TEST',
                          'status': 'TEST',
                          'items': [
                            {'quantity': 1, 'name': 'Printer test'},
                          ],
                        });
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Test ticket sent to printer')),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No Sunmi printer on this device. KOT prints on Sunmi tablets only.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ]),
                
                const SizedBox(height: 24),

                // Display
                _buildSectionHeader('Display'),
                _buildCard([
                  _buildThemeModeTile(context, ref, prefs),
                  const Divider(height: 1, color: AppColors.gray200),
                  _buildSwitchTile(
                    icon: Iconsax.maximize,
                    title: 'Compact Density',
                    subtitle: 'Smaller cards and padding for high-volume stores',
                    value: prefs.compactDensity,
                    onChanged: (v) => ref
                        .read(kitchenPreferencesProvider.notifier)
                        .setCompactDensity(v),
                  ),
                ]),

                const SizedBox(height: 24),

                // Notifications
                _buildSectionHeader('Notifications'),
                _buildCard([
                  _buildSwitchTile(
                    icon: Iconsax.notification_bing,
                    title: 'Sound Notifications',
                    subtitle: 'Play sound for new orders',
                    value: prefs.soundEnabled,
                    onChanged: (v) => ref
                        .read(kitchenPreferencesProvider.notifier)
                        .setSoundEnabled(v),
                  ),
                  const Divider(height: 1, color: AppColors.gray200),
                  _buildSwitchTile(
                    icon: Iconsax.warning_2,
                    title: 'Show Test Orders',
                    subtitle: 'Display simulated orders in the KDS',
                    value: prefs.showTestOrders,
                    onChanged: (v) => ref
                        .read(kitchenPreferencesProvider.notifier)
                        .setShowTestOrders(v),
                  ),
                ]),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.logout),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Kitchen App v1.0.0',
                    style: TextStyle(color: isDark ? AppColors.gray700 : AppColors.gray500, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.gray200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SwitchListTile(
      secondary: Icon(icon, color: isDark ? AppColors.darkTextSecondary : AppColors.gray700),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.gray700, fontSize: 12)),
      value: value,
      activeThumbColor: AppColors.white50,
      activeTrackColor: AppColors.success,
      inactiveThumbColor: AppColors.white50,
      inactiveTrackColor: AppColors.gray400,
      onChanged: onChanged,
    );
  }

  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref, KitchenPreferences prefs) {
    final labels = {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    };
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(Iconsax.moon, color: isDark ? AppColors.darkTextSecondary : AppColors.gray700),
      title: Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      subtitle: Text(labels[prefs.themeMode] ?? 'System', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.gray700, fontSize: 12)),
      trailing: Icon(Iconsax.arrow_right_3, size: 16, color: isDark ? AppColors.gray700 : AppColors.gray500),
      onTap: () async {
        final selected = await showModalBottomSheet<ThemeMode>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _ThemePicker(current: prefs.themeMode),
        );
        if (selected != null) {
          await ref.read(kitchenPreferencesProvider.notifier).setThemeMode(selected);
        }
      },
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode current;

  const _ThemePicker({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final options = [
      (ThemeMode.system, 'System', 'Match device setting'),
      (ThemeMode.light, 'Light', 'Default bright theme'),
      (ThemeMode.dark, 'Dark', 'High contrast for dim kitchens'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              ...options.map((option) {
                final (mode, title, subtitle) = option;
                final selected = mode == current;
                return ListTile(
                  leading: Icon(
                    mode == ThemeMode.dark
                        ? Iconsax.moon
                        : mode == ThemeMode.light
                            ? Iconsax.sun_1
                            : Iconsax.mobile,
                    color: selected ? AppColors.pandaPink : (isDark ? AppColors.darkTextSecondary : AppColors.gray700),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.pandaPink : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.gray700),
                  ),
                  trailing: selected
                      ? const Icon(Iconsax.tick_circle, color: AppColors.pandaPink)
                      : null,
                  onTap: () => Navigator.pop(context, mode),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
