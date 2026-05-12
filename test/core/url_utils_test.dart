import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/core/utils/url_utils.dart';

void main() {
  group('hostFromUrl', () {
    test('extracts host from full URL', () {
      expect(hostFromUrl('https://www.amazon.sa/dp/test'), 'www.amazon.sa');
    });

    test('extracts host from URL without scheme', () {
      expect(hostFromUrl('noon.com'), 'noon.com');
    });

    test('returns empty string for empty URL', () {
      expect(hostFromUrl(''), '');
    });

    test('returns null for invalid URL', () {
      expect(hostFromUrl('not a url'), isNotNull);
    });
  });

  group('storeIdForHost', () {
    test('identifies amazon', () {
      expect(storeIdForHost('amazon.sa'), 'amazon');
      expect(storeIdForHost('www.amazon.sa'), 'amazon');
    });

    test('identifies noon', () {
      expect(storeIdForHost('noon.com'), 'noon');
    });

    test('identifies jarir', () {
      expect(storeIdForHost('jarir.com'), 'jarir');
    });

    test('returns null for unknown host', () {
      expect(storeIdForHost('example.com'), isNot(isNull));
    });
  });

  group('domainForStoreId', () {
    test('returns correct domain for amazon', () {
      expect(domainForStoreId('amazon'), 'amazon.sa');
    });

    test('returns correct domain for noon', () {
      expect(domainForStoreId('noon'), 'noon.com');
    });

    test('returns null for unknown store', () {
      expect(domainForStoreId('unknown_store'), isNull);
    });
  });

  group('inferStoreIdFromUrl', () {
    test('infers from amazon URL', () {
      expect(
        inferStoreIdFromUrl('https://www.amazon.sa/dp/B0ABC123'),
        'amazon',
      );
    });

    test('infers from name fallback', () {
      expect(
        inferStoreIdFromUrl('', fallbackName: 'نون'),
        'noon',
      );
    });

    test('infers from English name fallback', () {
      expect(
        inferStoreIdFromUrl('', fallbackName: 'Panda'),
        'panda',
      );
    });

    test('returns null for empty input', () {
      expect(inferStoreIdFromUrl(''), isNull);
    });
  });

  group('inferComparisonChannelType', () {
    test('returns marketplace for amazon', () {
      expect(
        inferComparisonChannelType('amazon', 'https://amazon.sa', 'Amazon'),
        'marketplace',
      );
    });

    test('returns pharmacy for nahdi', () {
      expect(
        inferComparisonChannelType('nahdi', 'https://nahdionline.com', 'نهدي'),
        'pharmacy',
      );
    });

    test('returns delivery for hungerstation', () {
      expect(
        inferComparisonChannelType(
          'hungerstation',
          'https://hungerstation.com',
          'HungerStation',
        ),
        'delivery',
      );
    });

    test('returns electronics for jarir', () {
      expect(
        inferComparisonChannelType('jarir', 'https://jarir.com', 'جرير'),
        'electronics',
      );
    });

    test('returns hypermarket for panda', () {
      expect(
        inferComparisonChannelType('panda', 'https://panda.sa', 'بنده'),
        'hypermarket',
      );
    });
  });

  group('normalizeStoreIdToken', () {
    test('lowercases and removes special chars', () {
      expect(normalizeStoreIdToken('AL-Dawaa_123'), 'aldawaa123');
    });
  });

  group('resolveStoreLogoUrl', () {
    test('returns favicon URL for known store', () {
      final url = resolveStoreLogoUrl(
        storeId: 'amazon',
        productUrl: 'https://amazon.sa/product',
      );

      expect(url, contains('google.com/s2/favicons'));
      expect(url, contains('amazon.sa'));
    });
  });
}
