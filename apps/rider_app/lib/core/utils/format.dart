/// Formatting helpers shared across the rider app.
library;

/// Formats a monetary [amount] in the app's `Tk` convention with two decimals,
/// e.g. `125.5` → `"Tk 125.50"`. Replaces the scattered
/// `'Tk ${x.toStringAsFixed(2)}'` literals across screens.
String formatCurrency(num amount) => 'Tk ${amount.toStringAsFixed(2)}';
