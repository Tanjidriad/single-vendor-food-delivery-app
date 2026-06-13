// Feature: admin-panel-redesign
//
// Property-based test for responsive breakpoint resolution.
//
// No third-party PBT package is available in this project, so we use randomized
// generation with dart:math as the property engine, supplemented with explicit
// boundary cases.
//
// - Property 12: Responsive breakpoint resolution

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/widgets/layouts/breakpoints.dart';

void main() {
  group('Property 12: Responsive breakpoint resolution', () {
    // Validates: Requirements 16.1
    //
    // For any viewport width W (positive number), the layout mode SHALL be:
    //   - compact  when W < 768
    //   - medium   when 768 <= W < 1200
    //   - expanded when W >= 1200

    const double compactThreshold = 768; // Breakpoints.compact
    const double mediumThreshold = 1200; // Breakpoints.medium
    const int iterations = 1000;

    // Reference oracle, independent of the implementation, expressing the
    // property exactly as stated in the design document.
    LayoutMode expectedMode(double width) {
      if (width < compactThreshold) return LayoutMode.compact;
      if (width < mediumThreshold) return LayoutMode.medium;
      return LayoutMode.expanded;
    }

    test('threshold constants match the specification', () {
      expect(Breakpoints.compact, compactThreshold);
      expect(Breakpoints.medium, mediumThreshold);
    });

    test('resolves correctly for random positive widths across full range', () {
      final random = Random(987654321);
      for (var i = 0; i < iterations; i++) {
        // Generate widths spanning well beyond the largest threshold so all
        // three regions are exercised, including fractional widths.
        final width = random.nextDouble() * 2400; // (0, 2400)
        expect(
          Breakpoints.fromWidth(width),
          expectedMode(width),
          reason: 'fromWidth($width) did not match the expected mode',
        );
      }
    });

    test('compact region: any width in (0, 768) resolves to compact', () {
      final random = Random(111);
      for (var i = 0; i < iterations; i++) {
        final width = random.nextDouble() * compactThreshold; // [0, 768)
        // nextDouble() can return 0.0; width 0 is still < 768 -> compact.
        expect(Breakpoints.fromWidth(width), LayoutMode.compact);
      }
    });

    test('medium region: any width in [768, 1200) resolves to medium', () {
      final random = Random(222);
      final span = mediumThreshold - compactThreshold; // 432
      for (var i = 0; i < iterations; i++) {
        final width = compactThreshold + random.nextDouble() * span; // [768,1200)
        // Guard against the (extremely unlikely) exact 1200 from rounding.
        if (width >= mediumThreshold) continue;
        expect(Breakpoints.fromWidth(width), LayoutMode.medium);
      }
    });

    test('expanded region: any width >= 1200 resolves to expanded', () {
      final random = Random(333);
      for (var i = 0; i < iterations; i++) {
        final width = mediumThreshold + random.nextDouble() * 2000; // [1200, 3200)
        expect(Breakpoints.fromWidth(width), LayoutMode.expanded);
      }
    });

    test('exact boundary values resolve to the correct mode', () {
      // Just below the compact/medium boundary -> compact.
      expect(Breakpoints.fromWidth(767.999), LayoutMode.compact);
      // Exactly at the compact threshold -> medium.
      expect(Breakpoints.fromWidth(768), LayoutMode.medium);
      // Just below the medium/expanded boundary -> medium.
      expect(Breakpoints.fromWidth(1199.999), LayoutMode.medium);
      // Exactly at the medium threshold -> expanded.
      expect(Breakpoints.fromWidth(1200), LayoutMode.expanded);
    });
  });
}
