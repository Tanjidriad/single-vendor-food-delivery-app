// Feature: admin-panel-redesign
//
// Property-based tests for the WButton size specification.
//
// These tests validate a universal correctness property from the design
// document. No third-party PBT package is available in this project, so we use
// randomized / exhaustive generation with dart:math as the property engine —
// the same convention used by test/core/theme/tokens_property_test.dart.
//
// - Property 3: Button size specification consistency

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/widgets/w_button.dart';

void main() {
  // The design document specifies a minimum of 100 iterations per property.
  // WButtonSize is a finite enum, so the exhaustive checks below are a complete
  // proof; the randomized sampling exceeds the minimum and guards the oracle.
  const int iterations = 1000;
  final random = Random(20240217);

  // Independent oracle describing the required size mapping straight from the
  // acceptance criteria (Requirement 2.4) and the design document
  // (sm -> 32/12/12/16, md -> 36/16/13/18, lg -> 40/20/14/20).
  //
  // Fields: height, horizontalPadding, textSize, iconSize.
  const Map<WButtonSize, ({double height, double hPadding, double text, double icon})>
      expectedSpec = {
    WButtonSize.sm: (height: 32, hPadding: 12, text: 12, icon: 16),
    WButtonSize.md: (height: 36, hPadding: 16, text: 13, icon: 18),
    WButtonSize.lg: (height: 40, hPadding: 20, text: 14, icon: 20),
  };

  group('Property 3: Button size specification consistency', () {
    // Validates: Requirements 2.4
    //
    // For any WButtonSize variant (sm, md, lg), the resolved height, horizontal
    // padding, text size, and icon size SHALL match the defined size mapping.
    // WButtonSize is a finite enum, so we verify the property exhaustively over
    // every value, and additionally sample randomly to exceed 100 iterations.

    test('the oracle covers every WButtonSize value', () {
      // Guards against the oracle drifting out of sync with the enum (e.g. a
      // new size being added without a corresponding expectation).
      expect(expectedSpec.keys.toSet(), WButtonSize.values.toSet());
    });

    test('every WButtonSize maps to the correct height/padding/text/icon', () {
      for (final size in WButtonSize.values) {
        final expected = expectedSpec[size]!;
        expect(
          size.height,
          expected.height,
          reason: '$size height should be ${expected.height}',
        );
        expect(
          size.horizontalPadding,
          expected.hPadding,
          reason: '$size horizontalPadding should be ${expected.hPadding}',
        );
        expect(
          size.textSize,
          expected.text,
          reason: '$size textSize should be ${expected.text}',
        );
        expect(
          size.iconSize,
          expected.icon,
          reason: '$size iconSize should be ${expected.icon}',
        );
      }
    });

    test(
        'property holds across randomly sampled sizes (exceeds 100 iterations)',
        () {
      for (var i = 0; i < iterations; i++) {
        final size = WButtonSize.values[random.nextInt(WButtonSize.values.length)];
        final expected = expectedSpec[size]!;

        expect(size.height, expected.height);
        expect(size.horizontalPadding, expected.hPadding);
        expect(size.textSize, expected.text);
        expect(size.iconSize, expected.icon);
      }
    });

    test('each dimension getter is positive for every size', () {
      // A simple invariant: no dimension should ever resolve to a non-positive
      // value, regardless of which size is chosen.
      for (final size in WButtonSize.values) {
        expect(size.height, greaterThan(0));
        expect(size.horizontalPadding, greaterThan(0));
        expect(size.textSize, greaterThan(0));
        expect(size.iconSize, greaterThan(0));
      }
    });
  });
}
