import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared app-bar shell for every kitchen screen.
///
/// Gives a consistent pink, edge-to-edge header with a softly rounded bottom
/// and light status-bar icons. Each screen supplies its own content via the
/// [overline]/[title]/[subtitle], an optional [trailing] action (e.g. the
/// accepting-orders toggle), an optional [leading] (e.g. a drawer button), and
/// an optional [bottom] row (e.g. the stats period toggle).
///
/// It relies on the surrounding board providing the top safe-area inset and a
/// pink scaffold background, so the header reads as flush to the top edge.
class KitchenHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final Widget? bottom;

  const KitchenHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.trailing,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Consume the status-bar inset here so the pink paints behind it,
    // giving an edge-to-edge header (the board no longer applies a top SafeArea).
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: ClipPath(
        clipper: _CurvedHeaderClipper(),
        child: Container(
        color: AppColors.pandaPink,
        padding: EdgeInsets.fromLTRB(
          18,
          14 + topInset,
          18,
          (bottom != null ? 14 : 20) + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overline != null && overline!.isNotEmpty)
                        Text(
                          overline!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (bottom != null) ...[const SizedBox(height: 14), bottom!],
          ],
        ),
        ),
      ),
    );
  }
}

/// Curved bottom edge — ported from the customer app's [AppCurvedEdgesClipper]
/// so the kitchen headers share the same signature curve.
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height);

    final firstCurve = Offset(0, size.height - 20);
    final lastCurve = Offset(30, size.height - 20);
    path.quadraticBezierTo(
      firstCurve.dx,
      firstCurve.dy,
      lastCurve.dx,
      lastCurve.dy,
    );

    final secondFirstCurve = Offset(0, size.height - 20);
    final secondLastCurve = Offset(size.width - 30, size.height - 20);
    path.quadraticBezierTo(
      secondFirstCurve.dx,
      secondFirstCurve.dy,
      secondLastCurve.dx,
      secondLastCurve.dy,
    );

    final thirdFirstCurve = Offset(size.width, size.height - 20);
    final thirdLastCurve = Offset(size.width, size.height);
    path.quadraticBezierTo(
      thirdFirstCurve.dx,
      thirdFirstCurve.dy,
      thirdLastCurve.dx,
      thirdLastCurve.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
