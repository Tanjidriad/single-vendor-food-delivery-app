/// View model for the rider COD cash reconciliation screen.
///
/// Maps the `/reports/rider/cash` payload. Tolerant parsing (mirrors
/// `earnings_summary.dart`): missing/malformed fields degrade to safe defaults.
library;

class CashSummary {
  /// Total COD cash collected from customers in the period.
  final num cashCollected;

  /// Number of COD deliveries in the period.
  final int ordersCount;

  /// Food revenue the rider must hand to the restaurant.
  final num foodToRemit;

  /// Delivery fee the rider keeps from COD cash.
  final num deliveryFeeKept;

  final List<CashEntry> entries;

  const CashSummary({
    required this.cashCollected,
    required this.ordersCount,
    required this.foodToRemit,
    required this.deliveryFeeKept,
    required this.entries,
  });

  /// Backward-compat alias used for the primary "amount to hand over" figure.
  num get cashToDeposit => foodToRemit;

  factory CashSummary.fromJson(Map<String, dynamic> json) {
    final cashCollected = _asNum(json['cashCollected']) ?? 0;
    final foodToRemit =
        _asNum(json['foodToRemit']) ?? _asNum(json['cashToDeposit']) ?? 0;
    final deliveryFeeKept =
        _asNum(json['deliveryFeeKept']) ??
        _asNum(json['deliveryFeesTotal']) ??
        _asNum(json['riderFeesTotal']) ??
        0;
    return CashSummary(
      cashCollected: cashCollected,
      ordersCount: _asInt(json['ordersCount']) ?? 0,
      foodToRemit: foodToRemit,
      deliveryFeeKept: deliveryFeeKept,
      entries: _asEntryList(json['entries']),
    );
  }
}

class CashEntry {
  final String orderNumber;

  /// Total cash collected from customer for this order.
  final num collected;

  /// Food portion the rider remits to the restaurant.
  final num toRemit;

  /// Delivery fee the rider keeps.
  final num kept;

  final String time;

  const CashEntry({
    required this.orderNumber,
    required this.collected,
    required this.toRemit,
    required this.kept,
    required this.time,
  });

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    final collected = _asNum(json['collected']) ?? _asNum(json['amount']) ?? 0;
    final kept =
        _asNum(json['kept']) ??
        _asNum(json['deliveryFeeKept']) ??
        _asNum(json['riderFee']) ??
        0;
    return CashEntry(
      orderNumber: _asString(json['orderNumber']) ?? '--',
      collected: collected,
      toRemit: _asNum(json['toRemit']) ?? _codFoodRemitFallback(collected, kept),
      kept: kept,
      time: _asString(json['time']) ?? '--',
    );
  }
}

num _codFoodRemitFallback(num collected, num kept) {
  final remit = collected - kept;
  return remit > 0 ? remit : 0;
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

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value is String ? value : value.toString();
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<CashEntry> _asEntryList(dynamic value) {
  if (value is! List) return const [];
  final entries = <CashEntry>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      entries.add(CashEntry.fromJson(item));
    } else if (item is Map) {
      entries.add(CashEntry.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return entries;
}
