/// Parse/view models for the rider Earnings_Summary (see design "Data Models").
///
/// These map the existing earnings endpoint payload (`Map<String, dynamic>`)
/// into typed objects without changing any backend contract. Parsing is
/// deliberately tolerant: missing or malformed optional fields degrade to
/// `null` or the `'--'` placeholder rather than throwing, so the Home_Sheet can
/// always render something even when the payload is partial (Requirement 1.4,
/// Correctness Property 1).
library;

/// Placeholder rendered in place of a value that is absent from the payload.
const String kEarningsPlaceholder = '--';

/// Aggregated earnings shown on the Home_Sheet.
class EarningsSummary {
  /// Today's total earnings. Sourced from `totalEarnings`, falling back to the
  /// backend's `deliveryFeesTotal`. Degrades to `0` when absent.
  final num todayTotal;

  /// Today's completed trip count. Sourced from `totalTrips`, falling back to
  /// the backend's `deliveries`. Degrades to `0` when absent.
  final int tripCount;

  /// Acceptance rate as a fraction/percentage from the payload. Optional;
  /// `null` when absent so the UI can render [kEarningsPlaceholder].
  final double? acceptanceRate;

  /// Human-readable online duration (e.g. "3h 20m"). Sourced from `onlineHours`;
  /// degrades to [kEarningsPlaceholder] when absent.
  final String hoursOnline;

  /// Withdrawable ledger balance from `pendingBalance`. Optional.
  final num? pendingBalance;

  /// Whether the rider has a positive balance ready for ops payout.
  final bool payoutReady;

  /// Admin-recorded payouts from `recentPayouts`. Empty when absent.
  final List<PayoutEntry> recentPayouts;

  /// Recent delivery entries from `history`. Empty when absent or malformed.
  final List<EarningsEntry> recentDeliveries;

  const EarningsSummary({
    required this.todayTotal,
    required this.tripCount,
    required this.acceptanceRate,
    required this.hoursOnline,
    this.pendingBalance,
    this.payoutReady = false,
    this.recentPayouts = const [],
    required this.recentDeliveries,
  });

  /// Tolerantly parses an [EarningsSummary] from a decoded JSON map.
  ///
  /// Every field is optional at the wire level: absent or wrong-typed values
  /// degrade to a safe default instead of throwing.
  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      todayTotal:
          _asNum(json['totalEarnings']) ??
          _asNum(json['deliveryFeesTotal']) ??
          0,
      tripCount:
          _asInt(json['totalTrips']) ?? _asInt(json['deliveries']) ?? 0,
      acceptanceRate: _asDouble(json['acceptanceRate']),
      hoursOnline: _asString(json['onlineHours']) ?? kEarningsPlaceholder,
      pendingBalance: _asNum(json['pendingBalance']),
      payoutReady: json['payoutReady'] == true,
      recentPayouts: _asPayoutList(json['recentPayouts']),
      recentDeliveries: _asEntryList(json['history']),
    );
  }
}

/// A single ops-recorded payout within an [EarningsSummary].
class PayoutEntry {
  final num amount;
  final String status;
  final String? reference;
  final String? note;
  final String dateLabel;

  const PayoutEntry({
    required this.amount,
    required this.status,
    this.reference,
    this.note,
    required this.dateLabel,
  });

  factory PayoutEntry.fromJson(Map<String, dynamic> json) {
    final paidAt = _parseDateTime(json['paidAt']);
    final createdAt = _parseDateTime(json['createdAt']);
    final date = paidAt ?? createdAt;
    final reference = _asString(json['reference']);

    final parts = <String>[
      if (date != null) _formatPayoutDate(date),
      if (reference != null) 'Ref: $reference',
    ];

    return PayoutEntry(
      amount: _asNum(json['amount']) ?? 0,
      status: _asString(json['status']) ?? kEarningsPlaceholder,
      reference: reference,
      note: _asString(json['note']),
      dateLabel: parts.isEmpty ? kEarningsPlaceholder : parts.join(' · '),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatPayoutDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final meridiem = date.hour >= 12 ? 'PM' : 'AM';
  return '$weekday, $month ${date.day} · $hour:$minute $meridiem';
}

/// A single recent-delivery line item within an [EarningsSummary].
class EarningsEntry {
  /// Amount earned for this entry. Degrades to `0` when absent.
  final num amount;

  /// Entry type/label (e.g. "Delivery"). Degrades to [kEarningsPlaceholder].
  final String type;

  /// Human-readable time of the entry. Degrades to [kEarningsPlaceholder].
  final String time;

  const EarningsEntry({
    required this.amount,
    required this.type,
    required this.time,
  });

  /// Tolerantly parses an [EarningsEntry] from a decoded JSON map.
  factory EarningsEntry.fromJson(Map<String, dynamic> json) {
    return EarningsEntry(
      amount: _asNum(json['amount']) ?? 0,
      type: _asString(json['type']) ?? kEarningsPlaceholder,
      time: _asString(json['time']) ?? kEarningsPlaceholder,
    );
  }
}

/// Coerces a dynamic value to [num], accepting numeric strings. Returns `null`
/// for `null`/empty/unparseable values.
num? _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }
  return null;
}

/// Coerces a dynamic value to [int] (truncating numerics). Returns `null` when
/// it cannot be interpreted as a number.
int? _asInt(dynamic value) => _asNum(value)?.toInt();

/// Coerces a dynamic value to [double]. Returns `null` when it cannot be
/// interpreted as a number.
double? _asDouble(dynamic value) => _asNum(value)?.toDouble();

/// Coerces a dynamic value to a non-empty [String]. Returns `null` for
/// `null`/empty/blank values so callers can substitute a placeholder.
String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value is String ? value : value.toString();
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Parses a list of [EarningsEntry] from a dynamic value, skipping any element
/// that is not a JSON object. Returns an empty list when the value is absent or
/// not a list.
List<EarningsEntry> _asEntryList(dynamic value) {
  if (value is! List) return const [];
  final entries = <EarningsEntry>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      entries.add(EarningsEntry.fromJson(item));
    } else if (item is Map) {
      entries.add(EarningsEntry.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return entries;
}

List<PayoutEntry> _asPayoutList(dynamic value) {
  if (value is! List) return const [];
  final payouts = <PayoutEntry>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      payouts.add(PayoutEntry.fromJson(item));
    } else if (item is Map) {
      payouts.add(PayoutEntry.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return payouts;
}
