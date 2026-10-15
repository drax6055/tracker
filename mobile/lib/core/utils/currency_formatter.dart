import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(
    num amount, {
    String symbol = '₹',
    bool showDecimals = true,
    bool isIndian = true,
  }) {
    if (isIndian) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: symbol.isNotEmpty ? '$symbol ' : '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return formatter.format(amount);
    } else {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: symbol.isNotEmpty ? '$symbol ' : '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return formatter.format(amount);
    }
  }

  static String compact(num amount, {String symbol = '₹'}) {
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';

    if (absAmount >= 10000000) {
      // Crores
      final cr = (absAmount / 10000000).toStringAsFixed(2);
      return '$sign$symbol ${cr}Cr';
    } else if (absAmount >= 100000) {
      // Lakhs
      final lk = (absAmount / 100000).toStringAsFixed(2);
      return '$sign$symbol ${lk}L';
    } else if (absAmount >= 1000) {
      final k = (absAmount / 1000).toStringAsFixed(1);
      return '$sign$symbol ${k}k';
    }
    return '$sign$symbol ${absAmount.toStringAsFixed(0)}';
  }
}
