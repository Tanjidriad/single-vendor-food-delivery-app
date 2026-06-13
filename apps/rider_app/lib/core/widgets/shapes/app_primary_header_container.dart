import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_circular_container.dart';
import 'app_curved_edges.dart';

class AppPrimaryHeaderContainer extends StatelessWidget {
  const AppPrimaryHeaderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCurvedEdges(
      child: Container(
        color: AppColors.primary,
        child: Stack(
          children: [
            const Positioned(
              top: -150,
              right: -250,
              child: AppCircularContainer(),
            ),
            const Positioned(
              top: 100,
              right: -300,
              child: AppCircularContainer(),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
