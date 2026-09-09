import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/orders/presentation/assignment_navigation.dart';
import '../../features/orders/presentation/providers/active_order_restore.dart';
import '../../features/orders/presentation/providers/assignment_sync_controller.dart';
import '../../features/orders/presentation/providers/order_providers.dart';
import '../../features/orders/presentation/providers/socket_lifecycle_provider.dart';
import '../../features/shift/presentation/providers/rider_online_controller.dart';
import '../websockets/socket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The persistent bottom-navigation shell for the authenticated app.
///
/// Hosts five top-level branches in an [StatefulNavigationShell]
/// (Home · Earnings · Orders · History · Profile) and renders a custom bottom
/// bar with a centered, elevated crimson action button for Orders — the
/// rider's operational hub — in the spirit of the ZIPS reference.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _centerIndex = 2;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  Timer? _assignmentPollTimer;
  ProviderSubscription<bool>? _onlineListener;
  ProviderSubscription<Map<String, dynamic>?>? _activeOrderListener;
  ProviderSubscription<Map<String, dynamic>?>? _activeAssignmentListener;
  ProviderSubscription<AsyncValue<Map<String, dynamic>?>>?
      _incomingAssignmentListener;
  ProviderSubscription<AsyncValue<void>>? _socketConnectedListener;
  ProviderSubscription<Map<String, dynamic>?>? _pendingAssignmentListener;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool get _isIdleForOffers =>
      ref.read(isOnlineProvider) &&
      ref.read(activeOrderProvider) == null &&
      ref.read(activeAssignmentProvider) == null;

  Future<void> _presentPendingFromApi() async {
    if (!mounted || !_isIdleForOffers) return;

    final pending =
        await ref.read(assignmentSyncControllerProvider.notifier).syncNow();
    if (!mounted) return;

    for (final assignment in pending) {
      presentIncomingAssignmentIfIdle(ref, context, assignment);
      if (!_isIdleForOffers) break;
    }

    if (_isIdleForOffers) {
      tryPresentPendingAssignment(ref, context);
    }
  }

  void _configureAssignmentPolling() {
    _assignmentPollTimer?.cancel();
    _assignmentPollTimer = null;
    if (!_isIdleForOffers) return;

    unawaited(_presentPendingFromApi());
    _assignmentPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_presentPendingFromApi()),
    );
  }

  Future<void> _onAppResumed() async {
    if (!ref.read(isOnlineProvider)) return;
    await ref.read(authProvider.notifier).refreshSessionAfterResume();
    if (mounted) {
      await _presentPendingFromApi();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onlineListener = ref.listenManual(isOnlineProvider, (_, _) {
      _configureAssignmentPolling();
    });
    _activeOrderListener = ref.listenManual(activeOrderProvider, (previous, next) {
      _configureAssignmentPolling();
      if (previous != null && next == null && mounted) {
        unawaited(_presentPendingFromApi());
      }
    });
    _activeAssignmentListener =
        ref.listenManual(activeAssignmentProvider, (previous, next) {
      _configureAssignmentPolling();
      if (previous != null && next == null && mounted) {
        unawaited(_presentPendingFromApi());
      }
    });
    _incomingAssignmentListener =
        ref.listenManual(incomingAssignmentStreamProvider, (previous, next) {
      if (!next.hasValue || next.value == null) return;
      presentIncomingAssignmentIfIdle(
        ref,
        context,
        Map<String, dynamic>.from(next.value!),
      );
    });
    _socketConnectedListener =
        ref.listenManual(socketConnectedStreamProvider, (previous, next) {
      if (!next.hasValue) return;
      unawaited(_presentPendingFromApi());
    });
    _pendingAssignmentListener =
        ref.listenManual(pendingAssignmentProvider, (previous, next) {
      if (next == null) return;
      presentIncomingAssignmentIfIdle(
        ref,
        context,
        Map<String, dynamic>.from(next),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureAssignmentPolling();
      if (mounted) {
        tryPresentPendingAssignment(ref, context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _assignmentPollTimer?.cancel();
    _onlineListener?.close();
    _activeOrderListener?.close();
    _activeAssignmentListener?.close();
    _incomingAssignmentListener?.close();
    _socketConnectedListener?.close();
    _pendingAssignmentListener?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final socket = ref.read(socketServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        socket.setLifecycleAllowsReconnect(true);
        unawaited(_onAppResumed());
        _configureAssignmentPolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // During an active delivery the socket must stay alive in the
        // background so live location keeps broadcasting (the geolocator
        // foreground service keeps the process running). Only let the socket
        // go idle when there is no order in progress.
        final hasActiveOrder = ref.read(activeOrderProvider) != null;
        socket.setLifecycleAllowsReconnect(hasActiveOrder);
        _assignmentPollTimer?.cancel();
        _assignmentPollTimer = null;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(socketLifecycleProvider);
    ref.watch(assignmentSyncControllerProvider);
    ref.watch(activeOrderRestoreProvider);

    final current = widget.navigationShell.currentIndex;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _CenterActionButton(
        active: current == HomeShell._centerIndex,
        onTap: () => _goBranch(HomeShell._centerIndex),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: current,
        onTap: _goBranch,
        profileBadgeCount: unreadCount,
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Current orders',
      child: SizedBox(
        width: 60,
        height: 60,
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.primary),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                LucideIcons.package,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
    this.profileBadgeCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int profileBadgeCount;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surfaceLight,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 64,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: LucideIcons.house,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: LucideIcons.wallet,
              label: 'Earnings',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 64),
            _NavItem(
              icon: LucideIcons.clock,
              label: 'History',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: LucideIcons.user,
              label: 'Profile',
              selected: currentIndex == 4,
              badgeCount: profileBadgeCount,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: color),
                    if (badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
