// Feature: admin-panel-redesign
//
// Property-based tests for the WStatusBadge component and its status mappings.
//
// These tests validate universal correctness properties from the design
// document. No third-party PBT package is available in this project, so we use
// randomized / exhaustive generation with dart:math as the property engine,
// matching the convention established in test/core/theme/tokens_property_test.dart.
//
// - Property 6: StatusBadge variant color mapping consistency
// - Property 7: StatusBadge label formatting
// - Property 8: Status string to variant mapping with fallback

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/theme/tokens/app_tokens.dart';
import 'package:admin_app/core/widgets/status_mappings.dart';
import 'package:admin_app/core/widgets/w_status_badge.dart';

/// Charset whose `toUpperCase()` is length-preserving (single UTF-16 code unit
/// per character, no special casing like ß -> SS). This keeps length-based
/// assertions for Property 7 unambiguous while still exercising a wide input
/// space (mixed case letters, digits, spaces and common symbols).
const String _safeCharset =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_./#@';

String _randomString(Random random, int length) {
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(_safeCharset[random.nextInt(_safeCharset.length)]);
  }
  return buffer.toString();
}

void main() {
  // The design document specifies a minimum of 100 iterations per property;
  // we exceed that comfortably.
  const int iterations = 1000;
  final random = Random(20240218);

  // Expected semantic color for each variant, drawn from a given token set.
  Color expectedSemanticColor(StatusBadgeVariant variant, ColorTokens c) {
    return switch (variant) {
      StatusBadgeVariant.success => c.success,
      StatusBadgeVariant.warning => c.warning,
      StatusBadgeVariant.error => c.error,
      StatusBadgeVariant.info => c.info,
      StatusBadgeVariant.neutral => c.gray600,
    };
  }

  group('Property 6: StatusBadge variant color mapping consistency', () {
    // Validates: Requirements 4.2
    //
    // For any StatusBadgeVariant, resolveColor SHALL return the full semantic
    // color (success/warning/error/info, neutral -> gray600). The badge text
    // uses that full color and the background uses it at 10% alpha. The variant
    // domain is finite (5 values), so we verify it exhaustively against both
    // the light and dark token sets.

    final tokenSets = <String, ColorTokens>{
      'light': AppTokens.light.colors,
      'dark': AppTokens.dark.colors,
    };

    test('resolveColor returns the full semantic color for every variant', () {
      tokenSets.forEach((name, colors) {
        for (final variant in StatusBadgeVariant.values) {
          expect(
            WStatusBadge.resolveColor(variant, colors),
            expectedSemanticColor(variant, colors),
            reason: '$name tokens: variant $variant must resolve to its '
                'semantic color',
          );
        }
      });
    });

    test('backgroundAlpha token is 10%', () {
      expect(WStatusBadge.backgroundAlpha, 0.1);
    });

    test(
        'badge background equals the semantic color at 10% alpha and text uses '
        'the full semantic color', () {
      tokenSets.forEach((name, colors) {
        for (final variant in StatusBadgeVariant.values) {
          final semantic = WStatusBadge.resolveColor(variant, colors);
          final expectedBackground =
              semantic.withValues(alpha: WStatusBadge.backgroundAlpha);

          // Background = semantic color tinted to 10% alpha.
          expect(
            expectedBackground.a,
            closeTo(WStatusBadge.backgroundAlpha, 1e-9),
            reason: '$name/$variant background alpha must be 10%',
          );
          // RGB channels of the tint match the full semantic color.
          expect(expectedBackground.r, semantic.r,
              reason: '$name/$variant background red channel');
          expect(expectedBackground.g, semantic.g,
              reason: '$name/$variant background green channel');
          expect(expectedBackground.b, semantic.b,
              reason: '$name/$variant background blue channel');

          // Text color = full opacity semantic color.
          expect(semantic.a, closeTo(1.0, 1e-9),
              reason: '$name/$variant text color must be fully opaque');
        }
      });
    });

    testWidgets(
        'rendered badge applies tinted background and full-color text for '
        'every variant', (tester) async {
      final colors = AppTokens.light.colors; // default fallback token set
      for (final variant in StatusBadgeVariant.values) {
        const label = 'STATUS';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: WStatusBadge(label: label, variant: variant),
              ),
            ),
          ),
        );

        final semantic = WStatusBadge.resolveColor(variant, colors);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          semantic.withValues(alpha: WStatusBadge.backgroundAlpha),
          reason: 'variant $variant background must be 10% tint',
        );

        final text = tester.widget<Text>(find.text(label));
        expect(
          text.style?.color,
          semantic,
          reason: 'variant $variant text must use the full semantic color',
        );
      }
    });
  });

  group('Property 7: StatusBadge label formatting', () {
    // Validates: Requirements 4.3
    //
    // For any input label: the displayed text SHALL be the uppercase transform
    // of the input. For any input whose uppercase form exceeds 20 characters,
    // the displayed text SHALL be truncated to 20 characters with an ellipsis
    // appended.

    const int maxLen = WStatusBadge.maxLabelLength; // 20

    test('the maximum label length is 20', () {
      expect(maxLen, 20);
    });

    test('result is always uppercase (idempotent under toUpperCase)', () {
      for (var i = 0; i < iterations; i++) {
        final input = _randomString(random, random.nextInt(60));
        final result = WStatusBadge.formatLabel(input);
        expect(result, result.toUpperCase(),
            reason: 'formatted label must already be uppercase for "$input"');
      }
    });

    test('short labels are uppercased without truncation', () {
      for (var i = 0; i < iterations; i++) {
        // Lengths 0..20 are guaranteed <= maxLen for the safe charset.
        final input = _randomString(random, random.nextInt(maxLen + 1));
        final upper = input.toUpperCase();
        final result = WStatusBadge.formatLabel(input);

        expect(upper.length <= maxLen, isTrue,
            reason: 'generator sanity: "$input" should be within maxLen');
        expect(result, upper,
            reason: 'labels within maxLen must be the plain uppercase form');
        expect(result.contains('…'), isFalse,
            reason: 'short labels must not be truncated');
      }
    });

    test('long labels are truncated to 20 chars with an ellipsis', () {
      for (var i = 0; i < iterations; i++) {
        // Lengths 21..60 are guaranteed > maxLen for the safe charset.
        final input = _randomString(random, maxLen + 1 + random.nextInt(40));
        final upper = input.toUpperCase();
        final result = WStatusBadge.formatLabel(input);

        expect(upper.length > maxLen, isTrue,
            reason: 'generator sanity: "$input" should exceed maxLen');
        expect(result.endsWith('…'), isTrue,
            reason: 'truncated labels must end with an ellipsis');
        // 20 retained characters + 1 ellipsis character.
        expect(result.length, maxLen + 1,
            reason: 'truncated result must be exactly maxLen + ellipsis');
        expect(result.substring(0, maxLen), upper.substring(0, maxLen),
            reason: 'first 20 chars must match the uppercase input prefix');
      }
    });

    test('boundary cases at the truncation threshold', () {
      // Empty string.
      expect(WStatusBadge.formatLabel(''), '');

      // Exactly 20 chars -> no truncation.
      final exactly20 = 'a' * maxLen;
      expect(WStatusBadge.formatLabel(exactly20), 'A' * maxLen);
      expect(WStatusBadge.formatLabel(exactly20).contains('…'), isFalse);

      // 21 chars -> truncation.
      final exactly21 = 'b' * (maxLen + 1);
      final result21 = WStatusBadge.formatLabel(exactly21);
      expect(result21, '${'B' * maxLen}…');
      expect(result21.length, maxLen + 1);
    });
  });

  group('Property 8: Status string to variant mapping with fallback', () {
    // Validates: Requirements 4.4, 4.5, 4.6
    //
    // Known statuses map to their predefined variants; any string not in the
    // predefined set maps to neutral.

    const knownOrderStatuses = <String, StatusBadgeVariant>{
      'PENDING': StatusBadgeVariant.warning,
      'PREPARING': StatusBadgeVariant.info,
      'ON_THE_WAY': StatusBadgeVariant.info,
      'DELIVERED': StatusBadgeVariant.success,
      'CANCELLED': StatusBadgeVariant.error,
    };

    const knownRiderStatuses = <String, StatusBadgeVariant>{
      'APPROVED': StatusBadgeVariant.success,
      'PENDING': StatusBadgeVariant.warning,
      'REJECTED': StatusBadgeVariant.error,
      'SUSPENDED': StatusBadgeVariant.error,
    };

    test('every known order status maps to its predefined variant', () {
      knownOrderStatuses.forEach((status, expected) {
        expect(OrderStatusMapping.fromStatus(status), expected,
            reason: 'order status $status');
      });
    });

    test('every known rider status maps to its predefined variant', () {
      knownRiderStatuses.forEach((status, expected) {
        expect(RiderStatusMapping.fromStatus(status), expected,
            reason: 'rider status $status');
      });
    });

    test('any unknown string maps to neutral for both mappings', () {
      final orderKeys = knownOrderStatuses.keys.toSet();
      final riderKeys = knownRiderStatuses.keys.toSet();

      for (var i = 0; i < iterations; i++) {
        final candidate = _randomString(random, random.nextInt(15));

        if (!orderKeys.contains(candidate)) {
          expect(
            OrderStatusMapping.fromStatus(candidate),
            StatusBadgeVariant.neutral,
            reason: 'unknown order status "$candidate" must map to neutral',
          );
        }
        if (!riderKeys.contains(candidate)) {
          expect(
            RiderStatusMapping.fromStatus(candidate),
            StatusBadgeVariant.neutral,
            reason: 'unknown rider status "$candidate" must map to neutral',
          );
        }
      }
    });

    test('mapping is case-sensitive: lowercased known statuses are unknown', () {
      for (final status in {...knownOrderStatuses.keys, ...knownRiderStatuses.keys}) {
        final lower = status.toLowerCase();
        expect(OrderStatusMapping.fromStatus(lower), StatusBadgeVariant.neutral,
            reason: 'order mapping must be case-sensitive for "$lower"');
        expect(RiderStatusMapping.fromStatus(lower), StatusBadgeVariant.neutral,
            reason: 'rider mapping must be case-sensitive for "$lower"');
      }
    });

    test('empty string maps to neutral for both mappings', () {
      expect(OrderStatusMapping.fromStatus(''), StatusBadgeVariant.neutral);
      expect(RiderStatusMapping.fromStatus(''), StatusBadgeVariant.neutral);
    });
  });
}
