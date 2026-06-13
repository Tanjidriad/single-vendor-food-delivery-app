import 'package:flutter/material.dart';

import 'app_curved_edges_clipper.dart';

/// Wraps [child] with the curved bottom edge used on home / settings headers.
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
