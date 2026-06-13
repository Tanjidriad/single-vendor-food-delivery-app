import 'dart:math';

/// Stable key for a single checkout attempt (retries reuse the same key).
String createPlaceOrderIdempotencyKey() {
  final random = Random.secure().nextInt(0x7fffffff);
  return 'place-${DateTime.now().toUtc().millisecondsSinceEpoch}-$random';
}
