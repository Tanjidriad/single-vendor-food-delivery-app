import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/local_storage/storage_utility.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../force_update/presentation/providers/app_update_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Force-update gate: block builds below the server's minimum version.
    // Fails open (see appUpdateProvider) so a backend hiccup never locks users out.
    final update = await ref.read(appUpdateProvider.future);
    if (!mounted) return;
    if (update.updateRequired) {
      context.go(RoutePaths.forceUpdate);
      return;
    }

    final storage = ref.read(localStorageProvider);
    final onboardingDone = storage.readBool('onboarding_done') ?? false;
    if (!onboardingDone) {
      context.go(RoutePaths.onboarding);
      return;
    }

    final hasSession =
        await ref.read(authSessionProvider.notifier).restoreSession();
    if (!mounted) return;
    context.go(hasSession ? RoutePaths.home : RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/t-store-splash-logo-white.png',
              height: 120,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 700.ms,
                ),
            const SizedBox(height: 20),
            const Text(
              'WASABI',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
