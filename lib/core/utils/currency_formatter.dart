import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount,
      {String symbol = '৳', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String compact(double amount, {String symbol = '৳'}) {
    if (amount >= 1000000) {
      return '$symbol ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(2)}K';
    }
    return format(amount, symbol: symbol);
  }

  static String formatSimple(double amount, {String symbol = '৳'}) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}
