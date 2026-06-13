import 'w_status_badge.dart';

/// Predefined mapping from order status strings to [StatusBadgeVariant] values.
///
/// Maps the known order statuses to their semantic variants and falls back to
/// [StatusBadgeVariant.neutral] for any unrecognized string.
///
/// See Requirements 4.4 and 4.6, and design Property 8.
class OrderStatusMapping {
  const OrderStatusMapping._();

  /// Returns the [StatusBadgeVariant] for the given order [status] string.
  ///
  /// Known mappings:
  /// - `PENDING` → [StatusBadgeVariant.warning]
  /// - `PREPARING` → [StatusBadgeVariant.info]
  /// - `ON_THE_WAY` → [StatusBadgeVariant.info]
  /// - `DELIVERED` → [StatusBadgeVariant.success]
  /// - `CANCELLED` → [StatusBadgeVariant.error]
  ///
  /// Any other string returns [StatusBadgeVariant.neutral].
  static StatusBadgeVariant fromStatus(String status) {
    return switch (status) {
      'PENDING' => StatusBadgeVariant.warning,
      'PREPARING' => StatusBadgeVariant.info,
      'ON_THE_WAY' => StatusBadgeVariant.info,
      'DELIVERED' => StatusBadgeVariant.success,
      'CANCELLED' => StatusBadgeVariant.error,
      _ => StatusBadgeVariant.neutral,
    };
  }
}

/// Predefined mapping from rider approval status strings to
/// [StatusBadgeVariant] values.
///
/// Maps the known rider approval statuses to their semantic variants and falls
/// back to [StatusBadgeVariant.neutral] for any unrecognized string.
///
/// See Requirements 4.5 and 4.6, and design Property 8.
class RiderStatusMapping {
  const RiderStatusMapping._();

  /// Returns the [StatusBadgeVariant] for the given rider [status] string.
  ///
  /// Known mappings:
  /// - `APPROVED` → [StatusBadgeVariant.success]
  /// - `PENDING` → [StatusBadgeVariant.warning]
  /// - `REJECTED` → [StatusBadgeVariant.error]
  /// - `SUSPENDED` → [StatusBadgeVariant.error]
  ///
  /// Any other string returns [StatusBadgeVariant.neutral].
  static StatusBadgeVariant fromStatus(String status) {
    return switch (status) {
      'APPROVED' => StatusBadgeVariant.success,
      'PENDING' => StatusBadgeVariant.warning,
      'REJECTED' => StatusBadgeVariant.error,
      'SUSPENDED' => StatusBadgeVariant.error,
      _ => StatusBadgeVariant.neutral,
    };
  }
}
