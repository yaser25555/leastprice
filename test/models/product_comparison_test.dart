import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/data/models/product_comparison.dart';

void main() {
  group('ProductComparison', () {
    test('fromJson parses full product correctly', () {
      final json = {
        'expensive': {
          'name': 'نسكافيه جولد 200 جم',
          'price': 48.95,
          'imageUrl': 'https://example.com/nescafe.jpg',
        },
        'alternative': {
          'name': 'قهوة باجة السعودية 250 جم',
          'price': 24.50,
          'imageUrl': 'https://example.com/baja.jpg',
        },
        'categoryLabel': 'قهوة',
        'categoryId': 'coffee',
        'buyUrl': 'https://amazon.sa/dp/test',
        'rating': 4.6,
        'reviewCount': 184,
        'tags': ['نسكافيه', 'باجة'],
        'is_automated': true,
        'fragranceNotes': 'برغموت، فانيليا',
        'activeIngredients': 'كافيين',
      };

      final product = ProductComparison.fromJson(json);

      expect(product.categoryId, 'coffee');
      expect(product.categoryLabel, 'قهوة');
      expect(product.expensiveName, 'نسكافيه جولد 200 جم');
      expect(product.expensivePrice, 48.95);
      expect(product.alternativeName, 'قهوة باجة السعودية 250 جم');
      expect(product.alternativePrice, 24.50);
      expect(product.rating, 4.6);
      expect(product.reviewCount, 184);
      expect(product.tags, contains('نسكافيه'));
      expect(product.isAutomated, true);
      expect(product.fragranceNotes, 'برغموت، فانيليا');
      expect(product.activeIngredients, 'كافيين');
    });

    test('fromJson handles minimal data', () {
      final product = ProductComparison.fromJson({});

      expect(product.categoryLabel, isNotEmpty);
      expect(product.expensiveName, isNotEmpty);
      expect(product.alternativeName, isNotEmpty);
      expect(product.expensivePrice, 0);
      expect(product.alternativePrice, 0);
      expect(product.isAutomated, true);
    });

    test('savingsAmount returns correct difference', () {
      const product = ProductComparison(
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 100,
        expensiveImageUrl: '',
        alternativeName: 'Alternative',
        alternativePrice: 70,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 0,
        reviewCount: 0,
        tags: [],
      );

      expect(product.savingsAmount, 30);
    });

    test('savingsRatio returns correct ratio', () {
      const product = ProductComparison(
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 200,
        expensiveImageUrl: '',
        alternativeName: 'Alternative',
        alternativePrice: 80,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 0,
        reviewCount: 0,
        tags: [],
      );

      expect(product.savingsRatio, 0.6);
      expect(product.savingsPercent, 60);
      expect(product.isSuperSaving, true);
    });

    test('isSuperSaving false when below 40%', () {
      const product = ProductComparison(
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 100,
        expensiveImageUrl: '',
        alternativeName: 'Alternative',
        alternativePrice: 85,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 0,
        reviewCount: 0,
        tags: [],
      );

      expect(product.isSuperSaving, false);
    });

    test('copyWith preserves unchanged fields', () {
      const product = ProductComparison(
        categoryId: 'coffee',
        categoryLabel: 'قهوة',
        expensiveName: 'Original',
        expensivePrice: 50,
        expensiveImageUrl: '',
        alternativeName: 'Alt',
        alternativePrice: 25,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 4.0,
        reviewCount: 10,
        tags: ['tag1'],
      );

      final updated = product.copyWith(rating: 4.5);

      expect(updated.categoryId, 'coffee');
      expect(updated.expensiveName, 'Original');
      expect(updated.rating, 4.5);
      expect(updated.reviewCount, 10);
    });

    test('withUserRating calculates weighted average', () {
      const product = ProductComparison(
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 100,
        expensiveImageUrl: '',
        alternativeName: 'Alt',
        alternativePrice: 50,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 4.0,
        reviewCount: 9,
        tags: [],
      );

      final updated = product.withUserRating(5.0);

      expect(updated.reviewCount, 10);
      expect(updated.rating, closeTo(4.1, 0.01));
    });

    test('uniqueKey uses documentId when available', () {
      const product = ProductComparison(
        documentId: 'doc123',
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 100,
        expensiveImageUrl: '',
        alternativeName: 'Alt',
        alternativePrice: 50,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 0,
        reviewCount: 0,
        tags: [],
      );

      expect(product.uniqueKey, 'doc123');
    });

    test('searchTokens includes all searchable fields', () {
      const product = ProductComparison(
        categoryId: 'perfumes',
        categoryLabel: 'عطور',
        expensiveName: 'Dior Sauvage',
        expensivePrice: 520,
        expensiveImageUrl: '',
        alternativeName: 'بديل سافاج',
        alternativePrice: 189,
        alternativeImageUrl: '',
        buyUrl: '',
        rating: 4.9,
        reviewCount: 312,
        tags: ['سافاج', 'نخبة العود'],
        fragranceNotes: 'برغموت، فلفل',
        activeIngredients: 'كحول، عطر',
        localLocationLabel: 'الرياض',
        localLocationUrl: 'https://maps.google.com',
      );

      final tokens = product.searchTokens;

      expect(tokens, contains('عطور'));
      expect(tokens, contains('Dior Sauvage'));
      expect(tokens, contains('بديل سافاج'));
      expect(tokens, contains('برغموت، فلفل'));
      expect(tokens, contains('كحول، عطر'));
      expect(tokens, contains('الرياض'));
      expect(tokens, contains('سافاج'));
    });

    test('mockData is not empty', () {
      expect(ProductComparison.mockData, isNotEmpty);
      expect(ProductComparison.mockData.length, greaterThan(10));
    });

    test('toFirestoreMap contains required fields', () {
      const product = ProductComparison(
        categoryId: 'test',
        categoryLabel: 'اختبار',
        expensiveName: 'Original',
        expensivePrice: 100,
        expensiveImageUrl: 'https://example.com/img.jpg',
        alternativeName: 'Alt',
        alternativePrice: 50,
        alternativeImageUrl: 'https://example.com/alt.jpg',
        buyUrl: 'https://amazon.sa/dp/test',
        rating: 4.0,
        reviewCount: 5,
        tags: ['تاغ'],
      );

      final map = product.toFirestoreMap();

      expect(map['expensiveName'], 'Original');
      expect(map['expensivePrice'], 100);
      expect(map['alternativeName'], 'Alt');
      expect(map['alternativePrice'], 50);
      expect(map['category'], 'اختبار');
      expect(map['is_automated'], true);
      expect(map['rating'], 4.0);
      expect(map['reviewCount'], 5);
    });
  });
}
