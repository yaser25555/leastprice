import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';

void main() {
  group('ComparisonSearchResult', () {
    test('fromJson parses full result', () {
      final json = {
        'title': 'Samsung Galaxy S24',
        'price': '2,499 ر.س',
        'priceValue': 2499.0,
        'storeName': 'Noon',
        'storeId': 'noon',
        'storeLogoUrl': 'https://example.com/logo.png',
        'imageUrl': 'https://example.com/img.jpg',
        'productUrl': 'https://noon.com/product',
        'currency': 'SAR',
        'sourceType': 'serpapi',
        'channelType': 'marketplace',
        'isLiveDirect': false,
      };

      final result = ComparisonSearchResult.fromJson(json);

      expect(result.title, 'Samsung Galaxy S24');
      expect(result.price, 2499.0);
      expect(result.storeName, 'Noon');
      expect(result.storeId, 'noon');
      expect(result.currency, 'SAR');
      expect(result.isLiveDirect, false);
    });

    test('fromJson handles minimal data', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Product',
        'price': 'SAR 100',
        'link': 'https://example.com/p',
      });

      expect(result.title, 'Product');
      expect(result.price, greaterThan(0));
      expect(result.productUrl, isNotEmpty);
    });

    test('isScraped returns true for scraper source', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Test',
        'price': 'SAR 50',
        'link': 'https://example.com',
        'sourceType': 'scraper',
        'isLiveDirect': true,
      });

      expect(result.isScraped, true);
    });

    test('isPreferredMarketplace returns true for noon', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Product',
        'price': 'SAR 100',
        'link': 'https://noon.com',
        'storeId': 'noon',
      });

      expect(result.isPreferredMarketplace, true);
    });

    test('isPreferredMarketplace returns false for unknown store', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Product',
        'price': 'SAR 100',
        'link': 'https://unknown-store.com',
        'storeId': 'unknown',
      });

      expect(result.isPreferredMarketplace, false);
    });

    test('copyWith preserves unchanged fields', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Original',
        'price': 'SAR 100',
        'link': 'https://example.com',
      });

      final updated = result.copyWith(price: 80.0);

      expect(updated.title, 'Original');
      expect(updated.price, 80.0);
      expect(updated.productUrl, result.productUrl);
    });

    test('toJson contains required fields', () {
      final result = ComparisonSearchResult.fromJson({
        'title': 'Test Product',
        'price': 'SAR 200',
        'link': 'https://example.com/p',
        'storeId': 'amazon',
      });

      final json = result.toJson();

      expect(json['title'], 'Test Product');
      expect(json['priceValue'], 200);
      expect(json['storeId'], 'amazon');
      expect(json['sourceType'], isNotEmpty);
    });
  });
}
