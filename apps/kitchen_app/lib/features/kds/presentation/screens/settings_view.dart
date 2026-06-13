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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white50,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.setting_2, color: AppColors.pandaPink, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.black500),
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
                    title: Text(user?['fullName'] ?? 'Kitchen Staff', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black500)),
                    subtitle: Text(user?['email'] ?? 'staff@kitchen.com', style: const TextStyle(color: AppColors.gray700)),
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
                    leading: const Icon(Iconsax.link, color: AppColors.gray700),
                    title: const Text('Sunmi Printer Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.black500)),
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
                const Center(
                  child: Text(
                    'Kitchen App v1.0.0',
                    style: TextStyle(color: AppColors.gray500, fontSize: 13),
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
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.gray700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.gray200),
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
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.gray700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.black500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.gray700, fontSize: 12)),
      value: value,
      activeColor: AppColors.white50,
      activeTrackColor: AppColors.success,
      inactiveThumbColor: AppColors.white50,
      inactiveTrackColor: AppColors.gray400,
      onChanged: onChanged,
    );
  }
}
