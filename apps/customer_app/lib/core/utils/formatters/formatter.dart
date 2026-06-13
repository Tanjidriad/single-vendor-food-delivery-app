import 'package:intl/intl.dart';

class AppFormatter {
  AppFormatter._();

  static String formatDate(DateTime? date, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(date ?? DateTime.now());
  }

  /// Bangladesh Taka formatting.
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'bn_BD',
      symbol: '৳',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Display +880 numbers readably.
  static String formatPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880') && digits.length >= 13) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
          '${digits.substring(5)}';
    }
    if (digits.length == 11 && digits.startsWith('01')) {
      return '+88 $digits';
    }
    return phoneNumber;
  }
}

typedef TFormatter = AppFormatter;
