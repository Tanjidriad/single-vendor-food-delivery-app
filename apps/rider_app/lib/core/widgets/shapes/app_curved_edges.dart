import 'package:flutter/material.dart';
import 'app_curved_edges_clipper.dart';

class AppCurvedEdges extends StatelessWidget {
  const AppCurvedEdges({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: AppCurvedEdgesClipper(),
      child: child,
    );
  }
}
