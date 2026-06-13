// Feature: admin-panel-redesign
//
// Property-based tests for sidebar navigation active-state logic.
//
// These tests validate universal correctness properties from the design
// document. No third-party PBT package is available in this project, so we use
// randomized / exhaustive generation with dart:math as the property engine,
// matching the convention established in
// test/core/theme/tokens_property_test.dart,
// test/core/widgets/w_status_badge_property_test.dart and
// test/core/widgets/w_data_table_property_test.dart.
//
// - Property 9: Navigation item active state determination

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/widgets/layouts/sidebar_navigation.dart';

void main() {
  // The design document specifies a minimum of 100 iterations per property;
  // we exceed that comfortably.
  const int iterations = 1000;
  final random = Random(20240221);

  // ---------------------------------------------------------------------------
  // Independent oracle
  // ---------------------------------------------------------------------------
  //
  // Property 9 rule: an item with route R is active for current path P iff
  //   P == R  OR  (R != '/'  AND  P startsWith R).
  //
  // The prefix check is implemented here by hand (character by character)
  // rather than via String.startsWith, so the oracle does not simply mirror
  // the implementation's own use of String.startsWith.
  bool oracleStartsWith(String p, String r) {
    if (r.length > p.length) return false;
    for (var i = 0; i < r.length; i++) {
      if (p.codeUnitAt(i) != r.codeUnitAt(i)) return false;
    }
    return true;
  }

  bool oracleActive(String path, String route) {
    if (path == route) return true;
    if (route == '/') return false;
    return oracleStartsWith(path, route);
  }

  // ---------------------------------------------------------------------------
  // Generators
  // ---------------------------------------------------------------------------
  //
  // A small vocabulary of segment names. It deliberately includes "order" and
  // "menu" alongside "orders"/"menus" so the generator naturally produces the
  // prefix-but-not-segment edge case (e.g. route "/order" vs path "/orders").
  const List<String> segmentPool = [
    'dashboard',
    'orders',
    'order',
    'menu',
    'menus',
    'addons',
    'banners',
    'coupons',
    'customers',
    'riders',
    'media',
    'a',
    'ab',
    '12',
    'x',
  ];

  String randomPath() {
    final count = random.nextInt(5); // 0..4 segments
    if (count == 0) return '/';
    final sb = StringBuffer();
    for (var i = 0; i < count; i++) {
      sb
        ..write('/')
        ..write(segmentPool[random.nextInt(segmentPool.length)]);
    }
    return sb.toString();
  }

  String randomRoute() {
    // Routes are usually single-segment top-level destinations, but we also
    // allow '/' and deeper routes to widen the input space.
    final roll = random.nextInt(10);
    if (roll == 0) return '/';
    return randomPath();
  }

  group('Property 9: Navigation item active state determination', () {
    // Validates: Requirements 5.3

    test('matches the independent oracle for random path/route pairs', () {
      for (var i = 0; i < iterations; i++) {
        final path = randomPath();
        final route = randomRoute();

        expect(
          isNavItemActive(path, route),
          oracleActive(path, route),
          reason: 'isNavItemActive("$path", "$route") disagreed with the '
              'oracle',
        );
      }
    });

    test('is reflexive: an item is always active on its own exact route', () {
      // P == R must always be active, including the root route '/'.
      for (var i = 0; i < iterations; i++) {
        final route = randomRoute();
        expect(
          isNavItemActive(route, route),
          isTrue,
          reason: 'a route must be active for its own exact path ("$route")',
        );
      }
      // Explicit root check.
      expect(isNavItemActive('/', '/'), isTrue);
    });

    test('root route "/" is active if and only if the path is exactly "/"', () {
      // Because '/' is a prefix of every absolute path, the rule deliberately
      // excludes it from prefix activation. Otherwise Dashboard would light up
      // on every screen.
      for (var i = 0; i < iterations; i++) {
        final path = randomPath();
        expect(
          isNavItemActive(path, '/'),
          path == '/',
          reason: 'root route must only be active for the exact "/" path, '
              'but path was "$path"',
        );
      }
    });

    test('a non-root route is active for any descendant path that has it as a '
        'prefix', () {
      for (var i = 0; i < iterations; i++) {
        // Build a non-root route, then a descendant by appending a child path.
        final route = '/${segmentPool[random.nextInt(segmentPool.length)]}';
        final childCount = random.nextInt(3) + 1; // 1..3 extra segments
        final sb = StringBuffer(route);
        for (var j = 0; j < childCount; j++) {
          sb
            ..write('/')
            ..write(segmentPool[random.nextInt(segmentPool.length)]);
        }
        final descendant = sb.toString();

        expect(
          isNavItemActive(descendant, route),
          isTrue,
          reason: 'route "$route" must be active for descendant '
              '"$descendant"',
        );
      }
    });

    test('unrelated routes (neither equal nor a prefix) are inactive', () {
      for (var i = 0; i < iterations; i++) {
        // Two distinct single-segment routes can never be a prefix of one
        // another, so neither activates the other.
        var a = segmentPool[random.nextInt(segmentPool.length)];
        var b = segmentPool[random.nextInt(segmentPool.length)];
        // Ensure b is not a prefix of a and a != b, to isolate the "unrelated"
        // case. Single segments where neither is a prefix of the other suffice.
        if (a == b || a.startsWith(b) || b.startsWith(a)) {
          a = 'orders';
          b = 'customers';
        }
        final path = '/$a';
        final route = '/$b';

        expect(
          isNavItemActive(path, route),
          isFalse,
          reason: 'unrelated route "$route" must be inactive for path '
              '"$path"',
        );
      }
    });

    test('prefix-but-not-segment edge cases follow the specified formula', () {
      // The rule is a raw string prefix test, so "/orders" is considered to
      // start with "/order". These cases pin that documented behaviour.
      expect(isNavItemActive('/orders', '/order'), isTrue,
          reason: '"/orders" starts with "/order" per the prefix rule');
      expect(isNavItemActive('/order', '/orders'), isFalse,
          reason: '"/order" does not start with "/orders"');
      expect(isNavItemActive('/menu/addons', '/menu'), isTrue,
          reason: 'a child route activates its ancestor');
      expect(isNavItemActive('/menus', '/menu'), isTrue,
          reason: '"/menus" starts with "/menu" per the prefix rule');
      expect(isNavItemActive('/menu', '/menus'), isFalse);
    });

    test('every real navigation route activates correctly for itself and a '
        'child path', () {
      for (final section in kNavSections) {
        for (final item in section.items) {
          final route = item.route;

          // Active on the exact route.
          expect(isNavItemActive(route, route), isTrue,
              reason: 'route "$route" must be active for itself');

          // Active on a child path under that route.
          final child = '$route/detail/42';
          expect(isNavItemActive(child, route), isTrue,
              reason: 'route "$route" must be active for child "$child"');

          // Inactive on the root path (unless the route itself is root).
          if (route != '/') {
            expect(isNavItemActive('/', route), isFalse,
                reason: 'route "$route" must be inactive on the root path');
          }
        }
      }
    });
  });
}
