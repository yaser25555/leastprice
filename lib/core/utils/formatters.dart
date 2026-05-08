import 'package:leastprice/core/utils/helpers.dart';

String formatPrice(double price) {
  return '${formatAmountValue(price)} ${tr('ر.س', 'SAR')}';
}

String formatAmountValue(double amount) {
  final hasFraction = amount != amount.roundToDouble();
  return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

double? extractMarketplacePrice(String text) {
  // 1. Initial cleanup: handle Arabic separators and remove commas for thousands
  final cleanText = text
      .replaceAll('٫', '.')
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .replaceAll('،', '')
      .trim();

  if (cleanText.isEmpty) return null;

  const currencySymbols =
      r'(?:SAR|ر\.?\s?س|ريال(?:\s+سعودي)?|SR|S\.R|ريالاً|ريالات)';

  // 2. Try explicit matches with currency nearby (High Confidence)
  final explicitPatterns = [
    RegExp('$currencySymbols\\s*([0-9]+(?:\\.[0-9]{1,3})?)',
        caseSensitive: false),
    RegExp('([0-9]+(?:\\.[0-9]{1,3})?)\\s*$currencySymbols',
        caseSensitive: false),
  ];

  for (final pattern in explicitPatterns) {
    final match = pattern.firstMatch(cleanText);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
  }

  // 3. Fallback: Find all numeric candidates and pick the most likely one (Usually the last one)
  final allMatches =
      RegExp(r'([0-9]+(?:\.[0-9]{1,3})?)').allMatches(cleanText).toList();
  if (allMatches.isEmpty) return null;

  const forbiddenUnits = [
    'k',
    'inch',
    'بوصة',
    'جم',
    'مل',
    'جرام',
    'كجم',
    'وات',
    'w',
    'v',
    'هرتز',
    'hz',
    'gb',
    'mb',
    'tb',
    'جيجا',
    'ميج',
    'بكسل',
    'pixel',
    'l',
    'لتر',
    'pcs',
    'حبة',
    'قطعة'
  ];

  final candidates = <double>[];
  for (final match in allMatches) {
    final val = double.tryParse(match.group(1) ?? '');
    if (val == null || val <= 0) continue;

    // Check context for units
    final end = match.end;
    final context = cleanText
        .substring(end, (end + 15).clamp(0, cleanText.length))
        .toLowerCase();
    final isForbidden = forbiddenUnits.any((u) => context.contains(u));

    if (!isForbidden) {
      candidates.add(val);
    }
  }

  if (candidates.isEmpty) return null;

  // Most prices in shopping results appear at the end of snippets or cards
  return candidates.last;
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
