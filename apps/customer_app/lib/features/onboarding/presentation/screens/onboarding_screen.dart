import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/local_storage/storage_utility.dart';
import '../widgets/onboarding_action_buttons.dart';
import '../widgets/onboarding_indicator.dart';
import '../widgets/onboarding_logo.dart';
import '../widgets/onboarding_slide_model.dart';
import '../widgets/onboarding_slide_page.dart';

/// Stunning, modern onboarding screen with micro-animated vector illustrations,
/// dynamic page indicator, and localized theme configurations.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _page = 0;

  // Floating micro-animation controller for vector SVGs
  late final AnimationController _animationController;
  late final Animation<double> _floatAnimation;

  // List of high-fidelity slides matching exact copy guidelines
  static const List<OnboardingSlideModel> _slides = [
    OnboardingSlideModel(
      assetPath: 'assets/illustrations/onboarding_cook.svg',
      title: 'Welcome to the\nmost tastiest app',
      subtitle: 'You know, this app is edible meaning you\ncan eat it!',
    ),
    OnboardingSlideModel(
      assetPath: 'assets/illustrations/onboarding_rider.svg',
      title: 'We use nitro on\nbicycles for delivery!',
      subtitle: 'For very fast delivery we use nitro on\nbicycles, kidding, but we’re very fast.',
    ),
    OnboardingSlideModel(
      assetPath: 'assets/illustrations/onboarding_birthday.svg',
      title: 'We’re the besties\nof birthday peoples',
      subtitle: 'We send cakes to our plus members, (only\none cake per person)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initFloatingAnimation();
  }

  void _initFloatingAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Finalizes onboarding state in local storage and routes to landing pages
  Future<void> _finishOnboarding({required bool register}) async {
    await ref.read(localStorageProvider).writeBool('onboarding_done', true);
    if (!mounted) return;
    context.go(register ? RoutePaths.register : RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const OnboardingLogo(),
            
            // Expanded Page View slider area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  return OnboardingSlidePage(
                    slide: _slides[i],
                    isCurrentPage: _page == i,
                    floatAnimation: _floatAnimation,
                  );
                },
              ),
            ),

            // Page Indicator dots
            OnboardingIndicator(
              itemCount: _slides.length,
              currentPage: _page,
            ),
            
            const SizedBox(height: 32),

            // Interactive Bottom Buttons
            OnboardingActionButtons(
              isLastPage: _page == _slides.length - 1,
              onSkip: () => _finishOnboarding(register: false),
              onNext: () {
                if (_page < _slides.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finishOnboarding(register: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
