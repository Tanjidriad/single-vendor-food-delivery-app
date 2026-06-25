/// Formatting helpers shared across the rider app.
library;

/// Formats a monetary [amount] in the app's `Tk` convention with two decimals,
/// e.g. `125.5` → `"Tk 125.50"`. Replaces the scattered
/// `'Tk ${x.toStringAsFixed(2)}'` literals across screens.
String formatCurrency(num amount) => 'Tk ${amount.toStringAsFixed(2)}';

/// Compact relative time for notification rows.
String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
