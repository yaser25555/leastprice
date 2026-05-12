import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/core/utils/formatters.dart';

void main() {
  group('formatPrice', () {
    test('formats price with SAR currency', () {
      final result = formatPrice(49.99);
      expect(result, contains('49.99'));
      expect(result, contains('ر.س'));
    });

    test('formats whole number without decimals', () {
      final result = formatPrice(50.0);
      expect(result, contains('50'));
      expect(result, contains('ر.س'));
    });
  });

  group('formatAmountValue', () {
    test('shows decimals for fractional amounts', () {
      expect(formatAmountValue(49.99), '49.99');
    });

    test('shows integer for whole amounts', () {
      expect(formatAmountValue(100.0), '100');
    });

    test('handles large numbers', () {
      expect(formatAmountValue(12345.67), '12345.67');
    });
  });

  group('extractMarketplacePrice', () {
    test('extracts price with SAR currency prefix', () {
      expect(extractMarketplacePrice('SAR 49.99'), 49.99);
    });

    test('extracts price with Arabic currency suffix', () {
      expect(extractMarketplacePrice('49.99 ر.س'), 49.99);
    });

    test('extracts price with ريال suffix', () {
      expect(extractMarketplacePrice('199 ريال'), 199.0);
    });

    test('extracts price from mixed text', () {
      expect(extractMarketplacePrice('السعر: 75.50 ريال سعودي'), 75.50);
    });

    test('returns null for empty text', () {
      expect(extractMarketplacePrice(''), isNull);
    });

    test('returns null for text without numbers', () {
      expect(extractMarketplacePrice('مجاني'), isNull);
    });

    test('handles Arabic decimal separator', () {
      expect(extractMarketplacePrice('49.99 ر.س'), 49.99);
    });

    test('ignores measurement units', () {
      final result = extractMarketplacePrice('500 جم بسعر 25 ريال');
      expect(result, 25.0);
    });

    test('picks last number as price', () {
      expect(extractMarketplacePrice('200 جم - 45.50 ريال'), 45.50);
    });
  });

  group('normalizeArabic', () {
    test('normalizes alef variants to ا', () {
      expect(normalizeArabic('أحمد إبراهيم آدم'), 'احمد ابراهيم ادم');
    });

    test('normalizes taa marboota to ه', () {
      expect(normalizeArabic('مدرسة'), 'مدرسه');
    });

    test('normalizes alif maqsura to ي', () {
      expect(normalizeArabic('مستشفى'), 'مستشفي');
    });

    test('removes diacritics and extra spaces', () {
      expect(normalizeArabic('  قهوة   عربية  ').trim(), 'قهوه عربيه');
    });

    test('handles English text', () {
      expect(normalizeArabic('Coffee 123'), 'coffee 123');
    });

    test('removes special characters', () => expect(normalizeArabic('قهوة!@#'), 'قهوه'));
  });

  group('formatPercentage', () {
    test('formats percentage value', () {
      expect(formatPercentage(25.5), '25.50%');
    });

    test('formats whole percentage', () {
      expect(formatPercentage(50.0), '50%');
    });
  });

  group('formatSaudiPhoneNumber', () {
    test('formats +9665xxxxxxxx', () {
      expect(formatSaudiPhoneNumber('+966501234567'), '+966501234567');
    });

    test('formats 05xxxxxxxx', () {
      expect(formatSaudiPhoneNumber('0550123456'), '+966550123456');
    });

    test('formats 5xxxxxxxx', () {
      expect(formatSaudiPhoneNumber('550123456'), '+966550123456');
    });

    test('formats 9665xxxxxxxx', () {
      expect(formatSaudiPhoneNumber('966501234567'), '+966501234567');
    });

    test('returns null for invalid numbers', () {
      expect(formatSaudiPhoneNumber('123'), isNull);
    });
  });
}
