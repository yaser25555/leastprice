import 'package:leastprice/core/utils/helpers.dart';

String formatPrice(double price) {
  return '${formatAmountValue(price)} ${tr('ر.س', 'SAR')}';
}

String formatAmountValue(double amount) {
  final hasFraction = amount != amount.roundToDouble();
  return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

double? extractMarketplacePrice(String text) {
  final normalized = text
      .replaceAll('٫', '.')
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .replaceAll(
          RegExp(r'(?:SAR|ر\.?\s?س|ريال(?:\s+سعودي)?)', caseSensitive: false),
          ' ')
      .trim();
  if (normalized.isEmpty) {
    return null;
  }

  final patterns = <RegExp>[
    RegExp(
      r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
      caseSensitive: false,
    ),
    RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
  }

  return null;
}

String normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}


String formatPercentage(double value) {
  return '${formatAmountValue(value)}%';
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
