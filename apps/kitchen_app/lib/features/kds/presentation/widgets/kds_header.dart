import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../auth/widgets/pin_pad_dialog.dart';
import '../providers/restaurant_provider.dart';
import 'kitchen_header.dart';

class KdsHeader extends ConsumerWidget {
  final bool isConnected;
  final bool isRestaurantActive;
  final ValueChanged<bool> onToggleOnlineStatus;
  final VoidCallback? onMenuPressed;

  const KdsHeader({
    super.key,
    required this.isConnected,
    required this.isRestaurantActive,
    required this.onToggleOnlineStatus,
    this.onMenuPressed,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);
    final displayName = restaurantAsync.maybeWhen(
      data: (s) => s.displayName,
      orElse: () => 'Kitchen',
    );
    final prefs = ref.watch(kitchenPreferencesProvider);

    return KitchenHeader(
      overline: _greeting(),
      title: displayName,
      leading: onMenuPressed == null
          ? null
          : InkWell(
              onTap: onMenuPressed,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
            ),
      trailing: _AcceptingToggle(
        active: isRestaurantActive,
        onChanged: (newValue) async {
          // Going offline → require the manager PIN if one is set.
          if (!newValue && prefs.hasPinSet) {
            final ok = await showPinPadDialog(
              context,
              expectedPin: prefs.closingPin,
              title: 'Close Restaurant?',
              subtitle: 'Enter the manager PIN to stop accepting orders.',
            );
            if (!ok) return;
          }
          onToggleOnlineStatus(newValue);
        },
      ),
    );
  }
}

/// White status pill on the pink header: green dot + "Open" / amber + "Paused"
/// with a switch. The single most important control on the home screen.
class _AcceptingToggle extends StatelessWidget {
  final bool active;
  final ValueChanged<bool> onChanged;

  const _AcceptingToggle({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dotColor = active ? AppColors.success : AppColors.warning;
    return Semantics(
      label: active ? 'Pause taking orders' : 'Start taking orders',
      button: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 5, 6, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              active ? 'Open' : 'Paused',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black500,
              ),
            ),
            const SizedBox(width: 6),
            Transform.scale(
              scale: 0.78,
              child: CupertinoSwitch(
                value: active,
                activeTrackColor: AppColors.success,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
