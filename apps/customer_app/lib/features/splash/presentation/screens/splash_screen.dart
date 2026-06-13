import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/local_storage/storage_utility.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final storage = ref.read(localStorageProvider);
    final onboardingDone = storage.readBool('onboarding_done') ?? false;
    if (!onboardingDone) {
      context.go(RoutePaths.onboarding);
      return;
    }

    final hasSession = await ref.read(authSessionProvider.notifier).restoreSession();
    if (!mounted) return;
    context.go(hasSession ? RoutePaths.home : RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppColors.onPrimary),
            SizedBox(height: 16),
            Text(
              'Demo Kitchen',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
