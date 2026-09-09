import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/core/version/version_check.dart';

void main() {
  test('requires update when below the floor', () {
    expect(isUpdateRequired('1.0.0', '1.2.0'), isTrue);
    expect(isUpdateRequired('1.9.9', '2.0.0'), isTrue);
    expect(isUpdateRequired('1.1.5', '1.2.0'), isTrue);
  });

  test('does not require update at or above the floor', () {
    expect(isUpdateRequired('1.2.0', '1.2.0'), isFalse);
    expect(isUpdateRequired('1.3.0', '1.2.0'), isFalse);
    expect(isUpdateRequired('2.0.0', '1.9.9'), isFalse);
  });

  test('ignores build metadata and pre-release suffixes', () {
    expect(isUpdateRequired('1.2.0+42', '1.2.0'), isFalse);
    expect(isUpdateRequired('1.2.0-rc1', '1.2.0'), isFalse);
  });

  test('treats missing segments as zero', () {
    expect(isUpdateRequired('1.2', '1.2.0'), isFalse);
    expect(isUpdateRequired('1', '1.0.1'), isTrue);
  });
}
