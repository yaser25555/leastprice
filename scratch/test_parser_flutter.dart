
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

void main() {
  final testCases = [
    "١٬٢٩٩ ر.س",
    "Price: 1,500.00 SAR",
    "Nescafe 3 in 1 - 30 sachets - 45.00",
    "1,000 SAR",
    "500 SAR",
    "Qty: 1 Price: 100",
    "Smart TV 55 inch - 1500 SAR",
    "Iphone 15 Pro - 128GB - 4500",
    "Milk 1L - 5.50",
    "Buy 3 pieces for 15.00 SAR",
    "45.50"
  ];

  for (final tc in testCases) {
    final res = extractMarketplacePrice(tc);
    print('Input: "$tc" -> Result: $res SAR');
  }
}
