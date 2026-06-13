import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingLogo extends StatelessWidget {
  const OnboardingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Bobo',
        style: GoogleFonts.fredoka(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2C2C2C),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
