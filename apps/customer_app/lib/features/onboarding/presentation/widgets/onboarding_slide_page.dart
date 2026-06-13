import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_slide_model.dart';

class OnboardingSlidePage extends StatelessWidget {
  final OnboardingSlideModel slide;
  final bool isCurrentPage;
  final Animation<double> floatAnimation;

  const OnboardingSlidePage({
    super.key,
    required this.slide,
    required this.isCurrentPage,
    required this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hover translation + Scale-in effect
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value),
                child: AnimatedScale(
                  scale: isCurrentPage ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: child,
                ),
              );
            },
            child: SvgPicture.asset(
              slide.assetPath,
              width: 280,
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          // Heading Title
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C2C2C),
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description Subtitle
          Text(
            slide.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7F7F7F),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
