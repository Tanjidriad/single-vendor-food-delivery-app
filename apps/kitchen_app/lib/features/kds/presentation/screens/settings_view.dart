import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/services/sunmi_print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/widgets/pin_pad_dialog.dart';
import '../widgets/kitchen_header.dart';

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

    return Column(
      children: [
        const KitchenHeader(
          title: 'Settings',
          subtitle: 'Printer, display, alerts & security',
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
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
                    title: Text(
                      user?['fullName'] ?? 'Kitchen Staff',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      user?['email'] ?? 'Kitchen account',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray700,
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // Hardware & Printing
                _buildSectionHeader('Print'),
                _buildCard([
                  _buildSwitchTile(
                    icon: Iconsax.printer,
                    title: 'Auto-print new orders',
                    subtitle:
                        'Automatically print KOT when an order is accepted',
                    value: prefs.autoPrint,
                    onChanged: (v) => ref
                        .read(kitchenPreferencesProvider.notifier)
                        .setAutoPrint(v),
                  ),
                  const Divider(height: 1, color: AppColors.gray200),
                  ListTile(
                    leading: Icon(
                      Iconsax.link,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray700,
                    ),
                    title: Text(
                      'Sunmi Printer Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: printerReady
                                ? AppColors.success
                                : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          printerReady ? 'Ready' : 'Not detected',
                          style: TextStyle(
                            color: printerReady
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: AppColors.gray500,
                        ),
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
                          const SnackBar(
                            content: Text('Test ticket sent to printer'),
                          ),
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
                    subtitle:
                        'Smaller cards and padding for high-volume stores',
                    value: prefs.compactDensity,
                    onChanged: (v) => ref
                        .read(kitchenPreferencesProvider.notifier)
                        .setCompactDensity(v),
                  ),
                ]),

                const SizedBox(height: 24),

                // Alerts
                _buildSectionHeader('Alerts'),
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
                ]),

                const SizedBox(height: 24),

                // Security
                _buildSectionHeader('Security'),
                _buildCard([
                  ListTile(
                    leading: Icon(
                      Iconsax.lock,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray700,
                    ),
                    title: Text(
                      prefs.hasPinSet ? 'Closing PIN: Set' : 'Set Closing PIN',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      prefs.hasPinSet
                          ? 'PIN required to close the restaurant'
                          : 'No PIN — anyone can close the restaurant',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray700,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prefs.hasPinSet)
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Remove PIN?'),
                                  content: const Text(
                                    'This will allow anyone to close the restaurant without a PIN.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(kitchenPreferencesProvider.notifier)
                                    .clearClosingPin();
                              }
                            },
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        const Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: AppColors.gray500,
                        ),
                      ],
                    ),
                    onTap: () => _showSetPinFlow(context, ref, prefs),
                  ),
                ]),

                const SizedBox(height: 24),

                // Test Orders
                _buildSectionHeader('Test Orders'),
                _buildCard([
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.logout),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Kitchen App v1.0.0',
                    style: TextStyle(
                      color: isDark ? AppColors.gray700 : AppColors.gray500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Two-step flow: enter new PIN → confirm new PIN → save.
  Future<void> _showSetPinFlow(
    BuildContext context,
    WidgetRef ref,
    KitchenPreferences prefs,
  ) async {
    // Step 1 — if a PIN is already set, verify the old one first
    if (prefs.hasPinSet) {
      final verified = await showPinPadDialog(
        context,
        expectedPin: prefs.closingPin,
        title: 'Verify Current PIN',
        subtitle: 'Enter your current PIN before changing it.',
      );
      if (!verified || !context.mounted) return;
    }

    // Step 2 — enter new PIN
    final newPin = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CapturePinDialog(title: 'Enter New 4-digit PIN'),
    );
    if (newPin == null || !context.mounted) return;

    // Step 3 — confirm new PIN
    final confirmed = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CapturePinDialog(title: 'Confirm PIN'),
    );
    if (!context.mounted) return;

    if (confirmed != newPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match — please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(kitchenPreferencesProvider.notifier).setClosingPin(newPin);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Closing PIN saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
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
      secondary: Icon(
        icon,
        color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.white50,
      activeTrackColor: AppColors.success,
      inactiveThumbColor: AppColors.white50,
      inactiveTrackColor: AppColors.gray400,
      onChanged: onChanged,
    );
  }

  Widget _buildThemeModeTile(
    BuildContext context,
    WidgetRef ref,
    KitchenPreferences prefs,
  ) {
    final labels = {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    };
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        Iconsax.moon,
        color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
      ),
      title: Text(
        'Theme',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        labels[prefs.themeMode] ?? 'System',
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 16,
        color: isDark ? AppColors.gray700 : AppColors.gray500,
      ),
      onTap: () async {
        final selected = await showModalBottomSheet<ThemeMode>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _ThemePicker(current: prefs.themeMode),
        );
        if (selected != null) {
          await ref
              .read(kitchenPreferencesProvider.notifier)
              .setThemeMode(selected);
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
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
                    color: selected
                        ? AppColors.pandaPink
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray700),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.pandaPink
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray700,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Iconsax.tick_circle,
                          color: AppColors.pandaPink,
                        )
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

/// A PIN entry dialog that returns the raw entered string (does not validate).
/// Used when setting a new PIN.
class _CapturePinDialog extends StatefulWidget {
  final String title;
  const _CapturePinDialog({required this.title});

  @override
  State<_CapturePinDialog> createState() => _CapturePinDialogState();
}

class _CapturePinDialogState extends State<_CapturePinDialog> {
  String _entered = '';

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    setState(() => _entered += digit);
    if (_entered.length == 4) {
      final captured = _entered;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) Navigator.of(context).pop(captured);
      });
    }
  }

  void _onBack() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.pandaPink : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? AppColors.pandaPink
                          : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            ...keys.map(
              (row) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((k) {
                  if (k.isEmpty) return const SizedBox(width: 72, height: 56);
                  return GestureDetector(
                    onTap: k == '⌫' ? _onBack : () => _onKey(k),
                    child: Container(
                      width: 72,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: k == '⌫'
                          ? null
                          : BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                      child: k == '⌫'
                          ? Icon(
                              Icons.backspace_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurface,
                            )
                          : Text(
                              k,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
