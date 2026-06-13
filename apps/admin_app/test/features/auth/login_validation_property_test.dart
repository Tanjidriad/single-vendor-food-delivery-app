// Feature: admin-panel-redesign
//
// Property-based tests for login email validation.
//
// These tests validate a universal correctness property from the design
// document. No third-party PBT package is available in this project, so we use
// randomized generation with a seeded dart:math Random as the property engine
// (~1000 iterations per property), cross-checking the implementation against an
// independent oracle that mirrors the specification rule.
//
// - Property 13: Email validation correctness
//
// Validates: Requirements 19.6

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/features/auth/presentation/screens/login_screen.dart';

/// Independent oracle for Property 13, mirroring the specification rule
/// (Requirement 19.6) WITHOUT calling [isValidEmail].
///
/// The validator SHALL accept a string if and only if it contains at least one
/// `@` character followed by at least one `.` character, with at least one
/// character between the `@` and the `.` and at least one character after the
/// `.`. Empty strings SHALL be rejected.
///
/// This oracle is intentionally written from scratch (scanning the string)
/// rather than reusing the production logic, so divergences between the two can
/// be detected. It is total: it never throws for any input.
bool oracleIsValidEmail(String value) {
  if (value.isEmpty) return false;

  final atIndex = value.indexOf('@');
  if (atIndex < 0) return false;

  // Look for the first '.' that is at least two positions after the '@' (so
  // there is at least one character between '@' and '.'). The dot is only
  // accepted when at least one character follows it.
  for (var i = atIndex + 2; i < value.length; i++) {
    if (value[i] == '.') {
      return i < value.length - 1;
    }
  }
  return false;
}

void main() {
  // The design document specifies a minimum of 100 iterations per property; we
  // exceed that. A fixed seed keeps failures reproducible.
  const int iterations = 1000;
  final random = Random(20240217);

  // Alphabet for random local/domain/tld parts: lowercase letters plus digits.
  // Intentionally excludes '@' and '.' so structured generators stay valid.
  const String partAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  String randomPart(Random r, {int minLen = 1, int maxLen = 8}) {
    final len = minLen + r.nextInt(maxLen - minLen + 1);
    final buffer = StringBuffer();
    for (var i = 0; i < len; i++) {
      buffer.write(partAlphabet[r.nextInt(partAlphabet.length)]);
    }
    return buffer.toString();
  }

  group('Property 13: Email validation correctness', () {
    // Validates: Requirements 19.6

    test(
        'accepts any well-formed email (local@domain.tld with chars between '
        'and after the dot)', () {
      for (var i = 0; i < iterations; i++) {
        final local = randomPart(random);
        final domain = randomPart(random);
        final tld = randomPart(random);
        final email = '$local@$domain.$tld';

        expect(
          isValidEmail(email),
          isTrue,
          reason: 'isValidEmail("$email") should accept a well-formed email',
        );
        // Cross-check the oracle agrees this is the accepted shape.
        expect(
          oracleIsValidEmail(email),
          isTrue,
          reason: 'oracle should accept well-formed email "$email"',
        );
      }
    });

    test('rejects the empty string', () {
      expect(isValidEmail(''), isFalse);
      expect(oracleIsValidEmail(''), isFalse);
    });

    test('rejects strings containing no "@" character', () {
      for (var i = 0; i < iterations; i++) {
        // Build a random string with at least one character and no '@'. The
        // partAlphabet already excludes '@' and '.', so add an explicit '.'
        // sometimes to vary the shape while keeping the '@' absent.
        final base = randomPart(random);
        final value = random.nextBool() ? base : '$base.${randomPart(random)}';

        expect(value.contains('@'), isFalse, reason: 'generator invariant');
        expect(
          isValidEmail(value),
          isFalse,
          reason: 'isValidEmail("$value") should reject a string without "@"',
        );
        expect(oracleIsValidEmail(value), isFalse);
      }
    });

    test('rejects strings with "@" but no "." after the local part', () {
      for (var i = 0; i < iterations; i++) {
        final local = randomPart(random);
        final domain = randomPart(random); // no '.' present
        final value = '$local@$domain';

        expect(
          isValidEmail(value),
          isFalse,
          reason: 'isValidEmail("$value") should reject "@" with no following '
              '"."',
        );
        expect(oracleIsValidEmail(value), isFalse);
      }
    });

    test('rejects "@." with nothing between the "@" and the "."', () {
      for (var i = 0; i < iterations; i++) {
        final local = randomPart(random);
        final tld = randomPart(random);
        // The dot immediately follows the '@', so there is no character
        // between them; this must be rejected.
        final value = '$local@.$tld';

        expect(
          isValidEmail(value),
          isFalse,
          reason: 'isValidEmail("$value") should reject a dot immediately '
              'after "@"',
        );
        expect(oracleIsValidEmail(value), isFalse);
      }
    });

    test('rejects a trailing "." with nothing after it', () {
      for (var i = 0; i < iterations; i++) {
        final local = randomPart(random);
        final domain = randomPart(random);
        final value = '$local@$domain.'; // dot is the final character

        expect(
          isValidEmail(value),
          isFalse,
          reason: 'isValidEmail("$value") should reject a trailing "." with '
              'nothing after it',
        );
        expect(oracleIsValidEmail(value), isFalse);
      }
    });

    test(
        'matches the independent oracle for arbitrary character-soup inputs '
        '(accept iff valid pattern)', () {
      // The most general form of the property: for ANY input string, the
      // validator must agree with the oracle. We draw random strings over an
      // alphabet that includes '@' and '.' so the full input space (including
      // malformed inputs) is exercised.
      const String soupAlphabet = 'abc@.';

      for (var i = 0; i < iterations; i++) {
        final len = random.nextInt(9); // 0..8, includes the empty string
        final buffer = StringBuffer();
        for (var j = 0; j < len; j++) {
          buffer.write(soupAlphabet[random.nextInt(soupAlphabet.length)]);
        }
        final value = buffer.toString();

        final expected = oracleIsValidEmail(value);

        // Surface the exact counterexample if the implementation throws or
        // diverges from the oracle.
        bool actual;
        try {
          actual = isValidEmail(value);
        } catch (e) {
          fail('isValidEmail("$value") threw $e but the oracle returned '
              '$expected (accept iff valid pattern)');
        }

        expect(
          actual,
          expected,
          reason: 'isValidEmail("$value") returned $actual but the oracle '
              'returned $expected',
        );
      }
    });
  });
}
