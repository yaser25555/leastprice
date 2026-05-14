import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/features/home/store_offers_screen.dart';

void main() {
  setUp(() {
    appLang.value = 'ar';
  });

  Widget buildTestWidget({
    required String storeId,
    required String storeName,
    required String storeNameEn,
    required Color storeColor,
    String? storeLogoUrl,
    String? storeUrl,
    Stream<List<ProductComparison>>? productStream,
  }) {
    return ProviderScope(
      overrides: [
        allProductsStreamProvider.overrideWith((ref) {
          return productStream ?? const Stream.empty();
        }),
      ],
      child: MaterialApp(
        home: StoreOffersScreen(
          storeId: storeId,
          storeName: storeName,
          storeNameEn: storeNameEn,
          storeColor: storeColor,
          storeLogoUrl: storeLogoUrl,
          storeUrl: storeUrl,
        ),
      ),
    );
  }

  group('StoreOffersScreen', () {
    testWidgets('shows loading indicator while stream is pending', (
      tester,
    ) async {
      final controller = StreamController<List<ProductComparison>>();
      addTearDown(() => controller.close());

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: controller.stream,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add([]);
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('لا توجد عروض متاحة حالياً'), findsOneWidget);
    });

    testWidgets('shows error message on stream error', (tester) async {
      final controller = StreamController<List<ProductComparison>>();
      addTearDown(() => controller.close());

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: controller.stream,
        ),
      );
      await tester.pump();

      controller.addError(Exception('test error'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('فشل تحميل المنتجات'), findsOneWidget);
    });

    testWidgets('shows empty state when no products match', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('لا توجد عروض متاحة حالياً'), findsOneWidget);
    });

    testWidgets('shows visit store button when storeUrl provided and empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          storeUrl: 'https://www.amazon.sa',
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('زيارة أمازون'), findsOneWidget);
    });

    testWidgets('hides visit store button when no storeUrl and empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('زيارة أمازون'), findsNothing);
    });

    testWidgets('renders matching product cards', (tester) async {
      const products = [
        ProductComparison(
          categoryId: 'electronics',
          categoryLabel: 'إلكترونيات',
          expensiveName: 'Expensive Headphones',
          expensivePrice: 200.0,
          expensiveImageUrl: 'https://example.com/exp.jpg',
          alternativeName: 'Cheaper Headphones',
          alternativePrice: 120.0,
          alternativeImageUrl: 'https://example.com/alt.jpg',
          buyUrl: 'https://www.amazon.sa/dp/test',
          rating: 4.5,
          reviewCount: 100,
          tags: ['tag'],
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Expensive Headphones'), findsOneWidget);
      expect(find.text('Cheaper Headphones'), findsOneWidget);
      expect(find.text('إلكترونيات'), findsOneWidget);
    });

    testWidgets('filters out non-matching store products', (tester) async {
      const products = [
        ProductComparison(
          categoryId: 'test',
          categoryLabel: 'Test',
          expensiveName: 'Amazon Product',
          expensivePrice: 50.0,
          expensiveImageUrl: 'https://example.com/am.jpg',
          alternativeName: 'Amazon Alt',
          alternativePrice: 40.0,
          alternativeImageUrl: 'https://example.com/am2.jpg',
          buyUrl: 'https://www.amazon.sa/dp/123',
          rating: 4.0,
          reviewCount: 10,
          tags: ['tag'],
        ),
        ProductComparison(
          categoryId: 'test2',
          categoryLabel: 'Test2',
          expensiveName: 'Noon Specific',
          expensivePrice: 100.0,
          expensiveImageUrl: 'https://example.com/no.jpg',
          alternativeName: 'Noon Alt',
          alternativePrice: 80.0,
          alternativeImageUrl: 'https://example.com/no2.jpg',
          buyUrl: 'https://www.noon.com/product',
          rating: 4.0,
          reviewCount: 20,
          tags: ['tag2'],
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Amazon Product'), findsOneWidget);
      expect(find.text('Noon Specific'), findsNothing);
    });

    testWidgets('shows savings badge on deal card', (tester) async {
      const products = [
        ProductComparison(
          categoryId: 'test',
          categoryLabel: 'Test',
          expensiveName: 'Expensive',
          expensivePrice: 100.0,
          expensiveImageUrl: 'https://example.com/e.jpg',
          alternativeName: 'Cheap',
          alternativePrice: 70.0,
          alternativeImageUrl: 'https://example.com/c.jpg',
          buyUrl: 'https://www.amazon.sa/dp/save',
          rating: 4.0,
          reviewCount: 10,
          tags: ['tag'],
          isAutomated: false,
          generatedBy: 'store_deals_bot',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('وفر 30%'), findsOneWidget);
    });

    testWidgets('shows big saving label for 40%+ savings', (tester) async {
      const products = [
        ProductComparison(
          categoryId: 'test',
          categoryLabel: 'Test',
          expensiveName: 'Expensive',
          expensivePrice: 100.0,
          expensiveImageUrl: 'https://example.com/e.jpg',
          alternativeName: 'Cheap',
          alternativePrice: 50.0,
          alternativeImageUrl: 'https://example.com/c.jpg',
          buyUrl: 'https://www.amazon.sa/dp/big',
          rating: 4.0,
          reviewCount: 10,
          tags: ['tag'],
          isAutomated: false,
          generatedBy: 'store_deals_bot',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('توفير كبير 50%'), findsOneWidget);
    });

    testWidgets('renders store name in sliver app bar', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'noon',
          storeName: 'نون',
          storeNameEn: 'Noon',
          storeColor: const Color(0xFFFEE70B),
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('نون'), findsWidgets);
    });

    testWidgets('shows letter badge when no logo URL', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'noon',
          storeName: 'نون',
          storeNameEn: 'Noon',
          storeColor: const Color(0xFFFEE70B),
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('ن'), findsWidgets);
    });

    testWidgets('shows subtitle', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value([]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('عروض وبدائل أقل سعراً'), findsOneWidget);
    });

    testWidgets('shows buy button for products with buyUrl', (tester) async {
      const products = [
        ProductComparison(
          categoryId: 'test',
          categoryLabel: 'Test',
          expensiveName: 'Exp',
          expensivePrice: 100.0,
          expensiveImageUrl: 'https://example.com/e.jpg',
          alternativeName: 'Alt',
          alternativePrice: 70.0,
          alternativeImageUrl: 'https://example.com/a.jpg',
          buyUrl: 'https://www.amazon.sa/dp/btn',
          rating: 4.0,
          reviewCount: 10,
          tags: ['tag'],
          generatedBy: 'store_deals_bot',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('اشتري من أمازون'), findsOneWidget);
    });

    testWidgets('shows original price strikethrough when more expensive', (
      tester,
    ) async {
      const products = [
        ProductComparison(
          categoryId: 'test',
          categoryLabel: 'Test',
          expensiveName: 'Exp',
          expensivePrice: 150.0,
          expensiveImageUrl: 'https://example.com/e.jpg',
          alternativeName: 'Alt',
          alternativePrice: 99.50,
          alternativeImageUrl: 'https://example.com/a.jpg',
          buyUrl: 'https://www.amazon.sa/dp/strike',
          rating: 4.0,
          reviewCount: 10,
          tags: ['tag'],
          generatedBy: 'store_deals_bot',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          storeId: 'amazon',
          storeName: 'أمازون',
          storeNameEn: 'Amazon',
          storeColor: Colors.orange,
          productStream: Stream.value(products),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('150 ريال'), findsOneWidget);
      expect(find.text('99.50 ريال'), findsOneWidget);
    });
  });
}
