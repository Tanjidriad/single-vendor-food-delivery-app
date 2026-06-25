/// View model for the rider Performance insights screen.
///
/// Maps the `/reports/rider/performance` payload into a typed object. Parsing
/// is deliberately tolerant (mirroring `earnings_summary.dart`): missing or
/// malformed fields degrade to safe defaults rather than throwing, so the
/// screen always renders something even on a partial payload.
library;

class PerformanceSummary {
  /// Offers received in the selected period.
  final int offered;

  /// Offers accepted in the period.
  final int accepted;

  /// Deliveries completed in the period.
  final int deliveries;

  /// Assignments cancelled/unassigned in the period.
  final int cancelledCount;

  /// Accepted ÷ offered, as an integer percentage.
  final int acceptanceRate;

  /// Delivered ÷ accepted, as an integer percentage.
  final int completionRate;

  /// On-time deliveries ÷ timed deliveries, as an integer percentage.
  final int onTimeRate;

  /// Lifetime average rating (1–5).
  final double ratingAvg;

  /// Number of ratings behind [ratingAvg].
  final int ratingCount;

  const PerformanceSummary({
    required this.offered,
    required this.accepted,
    required this.deliveries,
    required this.cancelledCount,
    required this.acceptanceRate,
    required this.completionRate,
    required this.onTimeRate,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      offered: _asInt(json['offered']) ?? 0,
      accepted: _asInt(json['accepted']) ?? 0,
      deliveries: _asInt(json['deliveries']) ?? 0,
      cancelledCount: _asInt(json['cancelledCount']) ?? 0,
      acceptanceRate: _asInt(json['acceptanceRate']) ?? 100,
      completionRate: _asInt(json['completionRate']) ?? 100,
      onTimeRate: _asInt(json['onTimeRate']) ?? 100,
      ratingAvg: _asDouble(json['ratingAvg']) ?? 5.0,
      ratingCount: _asInt(json['ratingCount']) ?? 0,
    );
  }
}

num? _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }
  return null;
}

int? _asInt(dynamic value) => _asNum(value)?.toInt();
double? _asDouble(dynamic value) => _asNum(value)?.toDouble();
