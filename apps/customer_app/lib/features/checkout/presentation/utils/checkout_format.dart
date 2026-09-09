/// Parses a coordinate value that may arrive as a num, a String, or null.
double? coord(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Formats an address map into a single "line1, city" display line.
String formatAddressLine(Map<String, dynamic> address) {
  final line1 = address['line1'] as String? ?? '';
  final city = address['city'] as String?;
  return city != null && city.isNotEmpty ? '$line1, $city' : line1;
}
