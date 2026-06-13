// Feature: admin-panel-redesign
//
// Widget tests for the LoginScreen (Requirements 19.4, 19.5, 19.6, 19.7).
//
// Coverage:
//   * Form validation prevents submission (19.6, 19.7) — empty email, empty
//     password, and malformed email each block the login request and surface
//     the matching inline error below the respective field.
//   * Inline error display and clearing (19.4, 19.7) — validation errors render
//     below their field and clear as soon as the user edits that field; the
//     server credential error clears the same way.
//   * Loading state on submit button (19.5) — while AuthState.loading the
//     submit button shows a spinner and ignores taps.
//
// The real AuthNotifier hits FlutterSecureStorage (on build) and the auth
// repository (on login), so the screen is always mounted with `authProvider`
// overridden by a _FakeAuthNotifier. The fake seeds an explicit AuthState and
// records login calls instead of performing network I/O.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/widgets/w_button.dart';
import 'package:admin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:admin_app/features/auth/providers/auth_provider.dart';

/// A controllable [AuthNotifier] for widget tests.
///
/// Overrides [build] to skip the secure-storage bootstrap, seeds an explicit
/// [AuthState], and replaces [login] with a recorder that optionally simulates
/// an invalid-credential response (transitioning to [AuthState.error]) without
/// touching the network.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({
    this.initialState = AuthState.unauthenticated,
    this.loginError,
  });

  /// State returned by [build] (the seeded starting state).
  final AuthState initialState;

  /// When non-null, [login] sets this message and transitions to error,
  /// simulating an invalid-credential server response.
  final String? loginError;

  /// Records each `(email, password)` pair passed to [login].
  final List<(String, String)> loginCalls = [];

  int get loginCallCount => loginCalls.length;

  String? _errorOverride;

  @override
  String? get errorMessage => _errorOverride;

  @override
  AuthState build() => initialState;

  @override
  Future<void> login(String email, String password) async {
    loginCalls.add((email, password));
    if (loginError != null) {
      _errorOverride = loginError;
      state = AuthState.error;
    }
  }
}

/// Pumps the [LoginScreen] inside a themed [MaterialApp] with [authProvider]
/// overridden by [notifier].
Future<void> _pumpLogin(
  WidgetTester tester,
  _FakeAuthNotifier notifier,
) async {
  // A generous surface keeps the full glassmorphic card on-screen so every
  // field and the submit button are hittable without scrolling.
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// The email [TextField], located via its leading icon.
Finder _emailField() => find.ancestor(
      of: find.byIcon(Icons.email_outlined),
      matching: find.byType(TextField),
    );

/// The password [TextField], located via its leading icon.
Finder _passwordField() => find.ancestor(
      of: find.byIcon(Icons.lock_outline),
      matching: find.byType(TextField),
    );

void main() {
  group('LoginScreen form validation prevents submission '
      '(Requirements 19.6, 19.7)', () {
    testWidgets('empty email and password block submission and show both '
        'inline errors', (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      // Submit with both fields empty.
      await tester.tap(find.byType(WButton));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      // The login request was never dispatched.
      expect(notifier.loginCallCount, 0);
    });

    testWidgets('a malformed email blocks submission with the "valid email" '
        'error', (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      await tester.enterText(_emailField(), 'not-an-email');
      await tester.enterText(_passwordField(), 'secret123');
      await tester.tap(find.byType(WButton));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      // The empty-email message must not appear for a non-empty bad value.
      expect(find.text('Please enter your email'), findsNothing);
      expect(notifier.loginCallCount, 0);
    });

    testWidgets('a valid email with an empty password blocks submission',
        (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      await tester.enterText(_emailField(), 'admin@wasabi.com');
      await tester.tap(find.byType(WButton));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(notifier.loginCallCount, 0);
    });

    testWidgets('valid email and password dispatch the trimmed login request',
        (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      await tester.enterText(_emailField(), '  admin@wasabi.com  ');
      await tester.enterText(_passwordField(), 'secret123');
      await tester.tap(find.byType(WButton));
      await tester.pump();

      // No validation errors and exactly one login call with trimmed email.
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(notifier.loginCallCount, 1);
      expect(notifier.loginCalls.single, ('admin@wasabi.com', 'secret123'));
    });
  });

  group('LoginScreen inline error display and clearing '
      '(Requirements 19.4, 19.7)', () {
    testWidgets('editing the email field clears its validation error',
        (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      // Surface the email error.
      await tester.tap(find.byType(WButton));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);

      // Typing into the email field clears the inline error immediately.
      await tester.enterText(_emailField(), 'a');
      await tester.pump();
      expect(find.text('Please enter your email'), findsNothing);
    });

    testWidgets('editing the password field clears its validation error',
        (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      await tester.tap(find.byType(WButton));
      await tester.pump();
      expect(find.text('Please enter your password'), findsOneWidget);

      await tester.enterText(_passwordField(), 'x');
      await tester.pump();
      expect(find.text('Please enter your password'), findsNothing);
    });

    testWidgets('a server credential error renders below the form and clears '
        'when a field is edited', (tester) async {
      final notifier = _FakeAuthNotifier(loginError: 'Invalid credentials');
      await _pumpLogin(tester, notifier);

      // Submit valid input; the fake transitions to AuthState.error.
      await tester.enterText(_emailField(), 'admin@wasabi.com');
      await tester.enterText(_passwordField(), 'wrong-pass');
      await tester.tap(find.byType(WButton));
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);

      // Editing either field clears the credential error (Requirement 19.4).
      await tester.enterText(_emailField(), 'admin@wasabi.com2');
      await tester.pump();
      expect(find.text('Invalid credentials'), findsNothing);
    });
  });

  group('LoginScreen loading state on submit button (Requirement 19.5)', () {
    testWidgets('shows a spinner in the button while AuthState.loading',
        (tester) async {
      final notifier = _FakeAuthNotifier(initialState: AuthState.loading);
      await _pumpLogin(tester, notifier);

      // The button hosts a single progress spinner in place of its label.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables the submit button while loading so taps are ignored',
        (tester) async {
      final notifier = _FakeAuthNotifier(initialState: AuthState.loading);
      await _pumpLogin(tester, notifier);

      // Tapping the disabled button must not dispatch a login request.
      await tester.tap(find.byType(WButton), warnIfMissed: false);
      await tester.pump();

      expect(notifier.loginCallCount, 0);
    });

    testWidgets('shows no spinner when not loading', (tester) async {
      final notifier = _FakeAuthNotifier();
      await _pumpLogin(tester, notifier);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The label is visible in the resting state.
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
