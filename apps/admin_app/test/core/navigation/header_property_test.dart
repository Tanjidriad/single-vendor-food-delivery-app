// Feature: admin-panel-redesign
//
// Property-based tests for header bar logic: the notification badge text and
// the breadcrumb trail builder.
//
// These tests validate universal correctness properties from the design
// document. No third-party PBT package is available in this project, so we use
// randomized / exhaustive generation with dart:math as the property engine,
// matching the convention established in
// test/core/theme/tokens_property_test.dart,
// test/core/widgets/w_status_badge_property_test.dart and
// test/core/widgets/w_data_table_property_test.dart.
//
// - Property 10: Notification badge display logic
// - Property 11: Breadcrumb depth constraint

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/widgets/layouts/header_bar.dart';

void main() {
  // The design document specifies a minimum of 100 iterations per property;
  // we exceed that comfortably.
  const int iterations = 1000;
  final random = Random(20240223);

  group('Property 10: Notification badge display logic', () {
    // Validates: Requirements 6.4
    //
    // For any non-negative integer count, the badge SHALL be hidden (null)
    // when count == 0, show the numeric string when 1 <= count <= 99, and show
    // "99+" when count > 99.

    test('count == 0 hides the badge (returns null)', () {
      expect(notificationBadgeText(0), isNull);
    });

    test('counts 1..99 are shown verbatim (exhaustive)', () {
      // The 1..99 range is small enough to verify exhaustively.
      for (var count = 1; count <= 99; count++) {
        expect(
          notificationBadgeText(count),
          count.toString(),
          reason: 'count $count must render as its own numeric string',
        );
      }
    });

    test('the boundary at 99/100 switches to the "99+" cap', () {
      expect(notificationBadgeText(99), '99');
      expect(notificationBadgeText(100), '99+');
    });

    test('counts above 99 are capped at "99+" (random large values)', () {
      for (var i = 0; i < iterations; i++) {
        // 100 .. 1_000_099
        final count = 100 + random.nextInt(1000000);
        expect(
          notificationBadgeText(count),
          '99+',
          reason: 'count $count above 99 must be capped at "99+"',
        );
      }
    });

    test('matches an independent oracle across the full non-negative range', () {
      String? oracle(int count) {
        if (count == 0) return null;
        if (count > 99) return '99+';
        return '$count';
      }

      for (var i = 0; i < iterations; i++) {
        // Bias sampling toward the interesting 0..150 region while still
        // covering large values.
        final count = random.nextBool()
            ? random.nextInt(151) // 0..150 (covers 0, 1..99, 100..150)
            : random.nextInt(1 << 30); // large non-negative values
        expect(
          notificationBadgeText(count),
          oracle(count),
          reason: 'badge text for count $count disagreed with the oracle',
        );
      }
    });
  });

  group('Property 11: Breadcrumb depth constraint', () {
    // Validates: Requirements 6.7
    //
    // For any navigation path with N segments, the trail SHALL display at most
    // 4 levels, showing the last min(N, 4) segments with all but the final
    // segment being clickable.

    const List<String> segmentPool = [
      'dashboard',
      'orders',
      'menu',
      'addons',
      'banners',
      'coupons',
      'customers',
      'riders',
      'media',
      'detail',
      '42',
      'edit',
      'on_the_way',
    ];

    // Generates a path with `count` segments, plus randomly injected extra
    // slashes (leading, trailing, doubled) to exercise the split-and-filter
    // logic. Returns a record of (path, segmentCount).
    (String, int) randomPathWithSegments(int count) {
      final segments = <String>[
        for (var i = 0; i < count; i++)
          segmentPool[random.nextInt(segmentPool.length)],
      ];

      final sb = StringBuffer();
      // Optional leading slash noise.
      if (random.nextBool()) sb.write('/');
      for (var i = 0; i < segments.length; i++) {
        sb.write('/');
        // Occasionally double the slash to create empty segments that must be
        // filtered out.
        if (random.nextInt(5) == 0) sb.write('/');
        sb.write(segments[i]);
      }
      // Optional trailing slash noise.
      if (random.nextBool()) sb.write('/');

      return (sb.toString(), count);
    }

    test('depth, ordering, and clickability invariants hold for 0..8 segments',
        () {
      for (var i = 0; i < iterations; i++) {
        final segmentCount = random.nextInt(9); // 0..8 segments
        final (path, n) = randomPathWithSegments(segmentCount);

        final crumbs = buildBreadcrumbs(path);

        // Invariant 1: at most 4 (kBreadcrumbMaxLevels) levels are displayed.
        expect(
          crumbs.length,
          lessThanOrEqualTo(kBreadcrumbMaxLevels),
          reason: 'breadcrumbs must never exceed $kBreadcrumbMaxLevels levels '
              '(path "$path")',
        );

        // Invariant 2: exactly min(N, 4) segments are shown.
        final expectedShown = min(n, kBreadcrumbMaxLevels);
        expect(
          crumbs.length,
          expectedShown,
          reason: 'expected min($n, $kBreadcrumbMaxLevels) = $expectedShown '
              'crumbs for path "$path"',
        );

        if (crumbs.isEmpty) {
          continue;
        }

        // Invariant 3: all but the final segment are clickable; the final
        // (current) segment is never clickable.
        for (var j = 0; j < crumbs.length; j++) {
          final shouldBeClickable = j < crumbs.length - 1;
          expect(
            crumbs[j].isClickable,
            shouldBeClickable,
            reason: 'crumb at index $j (of ${crumbs.length}) clickability '
                'wrong for path "$path"',
          );
        }
        expect(crumbs.last.isClickable, isFalse,
            reason: 'the final crumb must never be clickable');

        // Invariant 4: the displayed crumbs are exactly the LAST min(N,4)
        // segments, in order. Compare against an independent oracle that
        // recomputes the trailing segments and their cumulative routes.
        final cleaned =
            path.split('/').where((s) => s.isNotEmpty).toList();
        expect(cleaned.length, n,
            reason: 'generator/oracle disagree on segment count for "$path"');

        // Cumulative routes for every cleaned segment.
        final cumulativeRoutes = <String>[];
        final buffer = StringBuffer();
        for (final seg in cleaned) {
          buffer
            ..write('/')
            ..write(seg);
          cumulativeRoutes.add(buffer.toString());
        }

        final start =
            cleaned.length > kBreadcrumbMaxLevels ? cleaned.length - kBreadcrumbMaxLevels : 0;
        final expectedRoutes = cumulativeRoutes.sublist(start);

        expect(
          crumbs.map((c) => c.route).toList(),
          expectedRoutes,
          reason: 'displayed crumb routes must be the last '
              '$expectedShown cumulative routes for path "$path"',
        );
      }
    });

    test('empty / slash-only paths produce no breadcrumbs', () {
      // Splitting on '/' and dropping empty parts leaves nothing for these
      // inputs, so the trail must be empty.
      for (final path in ['', '/', '//', '///']) {
        expect(buildBreadcrumbs(path), isEmpty,
            reason: 'path "$path" has no non-empty segments');
      }
    });

    test('a path with <= 4 segments shows every segment (no truncation)', () {
      for (var n = 1; n <= kBreadcrumbMaxLevels; n++) {
        final (path, count) = randomPathWithSegments(n);
        final crumbs = buildBreadcrumbs(path);
        expect(crumbs.length, count,
            reason: 'paths with <= $kBreadcrumbMaxLevels segments are shown in '
                'full (path "$path")');
        // Routes start from the very first segment when nothing is truncated.
        expect(crumbs.first.route.startsWith('/'), isTrue);
      }
    });

    test('a deep path keeps only the last 4 segments and drops the earliest',
        () {
      // 6 fixed segments -> only the last 4 are shown.
      const path = '/a/b/c/d/e/f';
      final crumbs = buildBreadcrumbs(path);

      expect(crumbs.length, 4);
      expect(crumbs.map((c) => c.route).toList(),
          ['/a/b/c', '/a/b/c/d', '/a/b/c/d/e', '/a/b/c/d/e/f']);
      // First three shown crumbs clickable, last one not.
      expect(crumbs[0].isClickable, isTrue);
      expect(crumbs[1].isClickable, isTrue);
      expect(crumbs[2].isClickable, isTrue);
      expect(crumbs[3].isClickable, isFalse);
    });

    test('respects a custom maxLevels argument', () {
      for (var i = 0; i < iterations; i++) {
        final maxLevels = random.nextInt(6) + 1; // 1..6
        final segmentCount = random.nextInt(9); // 0..8
        final (path, n) = randomPathWithSegments(segmentCount);

        final crumbs = buildBreadcrumbs(path, maxLevels: maxLevels);

        expect(crumbs.length, min(n, maxLevels),
            reason: 'with maxLevels=$maxLevels and $n segments, expected '
                '${min(n, maxLevels)} crumbs for path "$path"');
        expect(crumbs.length, lessThanOrEqualTo(maxLevels));
        if (crumbs.isNotEmpty) {
          expect(crumbs.last.isClickable, isFalse);
        }
      }
    });
  });
}
