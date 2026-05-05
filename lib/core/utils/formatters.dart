import 'package:intl/intl.dart';

String formatAmountValue(double value, {int decimalDigits = 2}) {
  if (value == value.truncateToDouble()) {
    return NumberFormat.decimalPattern().format(value.toInt());
  }
  return NumberFormat.currency(
    symbol: '',
    decimalDigits: decimalDigits,
  ).format(value).trim();
}

String formatPercentage(double value) {
  return '${formatAmountValue(value, decimalDigits: 1)}%';
}

String? formatSaudiPhoneNumber(String rawNumber) {
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+9665') && digits.length == 13) {
    return digits;
  }
  if (digits.startsWith('9665') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('05') && digits.length == 10) {
    return '+966${digits.substring(1)}';
  }
  if (digits.startsWith('5') && digits.length == 9) {
    return '+966$digits';
  }
  return null;
}
