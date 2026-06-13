import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route transition helpers for the admin panel.
///
/// The redesign uses a single, consistent fade transition for every route
/// (Requirement 17.3: no slide, scale, rotation, or bounce animations).
///
/// * ShellRoute children fade over 200ms (Requirement 17.1).
/// * The login route fades over 300ms (Requirement 17.2).
///
/// Because the [FadeTransition] is driven by the page's primary [animation],
/// the same fade is applied when the user navigates with the browser back and
/// forward buttons (Requirement 17.4). [reverseTransitionDuration] mirrors the
/// forward [duration] so reverse navigation animates with the same timing.

/// Default fade duration for navigation between ShellRoute children.
const Duration kShellFadeDuration = Duration(milliseconds: 200);

/// Fade duration used when navigating to or from the login screen.
const Duration kLoginFadeDuration = Duration(milliseconds: 300);

/// Builds a [CustomTransitionPage] that fades [child] in and out.
///
/// The fade is bound to the page's forward [animation], so reverse navigation
/// (including browser back/forward) reuses the same effect. The [key] should be
/// `state.pageKey` so GoRouter can correctly identify the page in its stack.
CustomTransitionPage<T> fadeTransition<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = kShellFadeDuration,
  Curve curve = Curves.easeInOut,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: child,
      );
    },
  );
}
