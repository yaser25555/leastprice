import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';

void main() {
  group('ExclusiveDeal', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'deal-1',
        'title': 'عرض حصري',
        'imageUrl': 'https://example.com/img.jpg',
        'beforePrice': 500.0,
        'afterPrice': 350.0,
        'expiryDate': '2026-12-31T23:59:59Z',
        'active': true,
        'dealUrl': 'https://panda.sa/deal',
      };

      final deal = ExclusiveDeal.fromJson(json);

      expect(deal.id, 'deal-1');
      expect(deal.title, 'عرض حصري');
      expect(deal.beforePrice, 500.0);
      expect(deal.afterPrice, 350.0);
      expect(deal.active, true);
      expect(deal.dealUrl, 'https://panda.sa/deal');
    });

    test('fromJson handles minimal data', () {
      final deal = ExclusiveDeal.fromJson({});

      expect(deal.title, isNotEmpty);
      expect(deal.beforePrice, 0);
      expect(deal.afterPrice, 0);
      expect(deal.active, true);
      expect(deal.expiryDate, isNotNull);
    });

    test('savingsAmount returns correct difference', () {
      final deal = ExclusiveDeal(
        id: 'test',
        title: 'Test',
        imageUrl: '',
        beforePrice: 200,
        afterPrice: 150,
        expiryDate: DateTime(2027, 1, 1),
      );

      expect(deal.savingsAmount, 50);
    });

    test('savingsPercent returns correct percentage', () {
      final deal = ExclusiveDeal(
        id: 'test',
        title: 'Test',
        imageUrl: '',
        beforePrice: 1000,
        afterPrice: 700,
        expiryDate: DateTime(2027, 1, 1),
      );

      expect(deal.savingsPercent, 30);
    });

    test('isExpiredAt returns true for past expiry', () {
      final deal = ExclusiveDeal(
        id: 'test',
        title: 'Test',
        imageUrl: '',
        beforePrice: 100,
        afterPrice: 80,
        expiryDate: DateTime(2020, 1, 1),
      );

      expect(deal.isExpiredAt(DateTime(2025, 1, 1)), true);
    });

    test('copyWith replaces specified fields', () {
      final original = ExclusiveDeal(
        id: 'orig',
        title: 'Original',
        imageUrl: '',
        beforePrice: 100,
        afterPrice: 80,
        expiryDate: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(
        title: 'Updated',
        afterPrice: 60,
      );

      expect(updated.id, 'orig');
      expect(updated.title, 'Updated');
      expect(updated.afterPrice, 60);
      expect(updated.beforePrice, 100);
    });

    test('toFirestoreMap contains required fields', () {
      final deal = ExclusiveDeal(
        id: 'test',
        title: 'Deal',
        imageUrl: 'https://example.com/img.jpg',
        beforePrice: 300,
        afterPrice: 199,
        expiryDate: DateTime(2026, 12, 31),
        active: true,
        dealUrl: 'https://example.com/buy',
      );

      final map = deal.toFirestoreMap();

      expect(map['title'], 'Deal');
      expect(map['beforePrice'], 300);
      expect(map['afterPrice'], 199);
      expect(map['active'], true);
      expect(map['dealUrl'], 'https://example.com/buy');
    });

    test('mockData has expected deals', () {
      expect(ExclusiveDeal.mockData, hasLength(4));
      expect(ExclusiveDeal.mockData[0].title, contains('سامسونج'));
      expect(ExclusiveDeal.mockData[1].title, contains('أبل'));
      expect(ExclusiveDeal.mockData[2].title, contains('دار الأميرات'));
      expect(ExclusiveDeal.mockData[3].title, contains('كبش نجد'));
    });
  });
}
