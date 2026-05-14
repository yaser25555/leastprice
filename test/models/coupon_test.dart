import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/data/models/coupon.dart';

void main() {
  group('Coupon', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'coupon-1',
        'code': 'SAVE20',
        'storeId': 'noon',
        'storeName': 'Noon',
        'discountLabel': '20% off',
        'discountPercent': 20,
        'expiresAt': '2026-12-31T23:59:59Z',
        'active': true,
      };

      final coupon = Coupon.fromJson(json);

      expect(coupon.id, 'coupon-1');
      expect(coupon.code, 'SAVE20');
      expect(coupon.storeId, 'noon');
      expect(coupon.storeName, 'Noon');
      expect(coupon.discountLabel, '20% off');
      expect(coupon.discountPercent, 20);
      expect(coupon.active, true);
    });

    test('isExpiredAt returns true for past expiry', () {
      final coupon = Coupon(
        id: 'test',
        code: 'TEST',
        storeId: 'amazon',
        storeName: 'Amazon',
        discountLabel: '10%',
        expiresAt: DateTime(2020, 1, 1),
      );

      expect(coupon.isExpiredAt(DateTime(2025, 1, 1)), true);
    });

    test('isExpiredAt returns false for future expiry', () {
      final coupon = Coupon(
        id: 'test',
        code: 'TEST',
        storeId: 'amazon',
        storeName: 'Amazon',
        discountLabel: '10%',
        expiresAt: DateTime(2027, 12, 31),
      );

      expect(coupon.isExpiredAt(DateTime(2025, 1, 1)), false);
    });

    test('copyWith replaces specified fields only', () {
      final original = Coupon(
        id: 'orig',
        code: 'OLD',
        storeId: 'amazon',
        storeName: 'Amazon',
        discountLabel: '5%',
        discountPercent: 5,
        expiresAt: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(
        code: 'NEW',
        discountPercent: 15,
      );

      expect(updated.id, 'orig');
      expect(updated.code, 'NEW');
      expect(updated.storeId, 'amazon');
      expect(updated.discountPercent, 15);
      expect(updated.expiresAt, DateTime(2025, 1, 1));
    });

    test('fromJson handles missing fields gracefully', () {
      final coupon = Coupon.fromJson({'code': 'TEST', 'storeId': 'amazon'});

      expect(coupon.code, 'TEST');
      expect(coupon.storeId, isNotEmpty);
      expect(coupon.active, true);
      expect(coupon.expiresAt, isNotNull);
    });

    test('isSupportedFeaturedStore returns true for valid storeId', () {
      final coupon = Coupon(
        id: 'test',
        code: 'TEST',
        storeId: 'noon',
        storeName: 'Noon',
        discountLabel: '10%',
        expiresAt: DateTime(2027, 1, 1),
      );

      expect(coupon.isSupportedFeaturedStore, true);
    });

    test('mockData has expected coupons', () {
      expect(Coupon.mockData, hasLength(46));
      expect(Coupon.mockData[0].storeId, 'noon');
      expect(Coupon.mockData[1].storeId, 'noon');
      expect(Coupon.mockData[2].storeId, 'noon');
      expect(Coupon.mockData[3].storeId, 'namshi');
      expect(Coupon.mockData[4].storeId, 'dar-al-amirat');
      expect(Coupon.mockData[5].storeId, 'kabsh-najd');
      expect(Coupon.mockData[6].storeId, 'vanier');
      expect(Coupon.mockData[7].storeId, 'rashfa-dhikra');
      expect(Coupon.mockData[8].storeId, 'roshen');
      expect(Coupon.mockData[9].storeId, 'roshen-tickets');
      expect(Coupon.mockData[10].storeId, 'al-reem');
      expect(Coupon.mockData[11].storeId, 'vibe');
      expect(Coupon.mockData[12].storeId, 'qatret-asal');
      expect(Coupon.mockData[13].storeId, 'itsmine');
      expect(Coupon.mockData[14].storeId, 'goldlolwa');
      expect(Coupon.mockData[15].storeId, 'goldlolwa');
      expect(Coupon.mockData[16].storeId, 'algharbi');
      expect(Coupon.mockData[17].storeId, 'mshkatmran');
      expect(Coupon.mockData[18].storeId, 'threeq');
      expect(Coupon.mockData[19].storeId, 'swanky');
      expect(Coupon.mockData[20].storeId, 'shaving360');
      expect(Coupon.mockData[21].storeId, 'mtjr');
      expect(Coupon.mockData[22].storeId, 'smarthub1');
      expect(Coupon.mockData[23].storeId, 'ragroastery');
      expect(Coupon.mockData[24].storeId, 'rakla');
      expect(Coupon.mockData[25].storeId, 'burgundy');
      expect(Coupon.mockData[26].storeId, 'takecard');
      expect(Coupon.mockData[27].storeId, 'sadacards');
      expect(Coupon.mockData[28].storeId, 'alanood');
      expect(Coupon.mockData[29].storeId, 'herfitness');
      expect(Coupon.mockData[30].storeId, 'eseven');
      expect(Coupon.mockData[31].storeId, 'cozmazone');
      expect(Coupon.mockData[32].storeId, 'bckyrdbbq');
      expect(Coupon.mockData[33].storeId, 'freesia');
      expect(Coupon.mockData[34].storeId, 'kilmananoud');
      expect(Coupon.mockData[35].storeId, 'worldgivenchy');
      expect(Coupon.mockData[36].storeId, 'bkam');
      expect(Coupon.mockData[37].storeId, 'retskin');
      expect(Coupon.mockData[38].storeId, 'retskin');
      expect(Coupon.mockData[39].storeId, 'madyalteb');
      expect(Coupon.mockData[40].storeId, 'marsil');
      expect(Coupon.mockData[41].storeId, 'almoqtas');
      expect(Coupon.mockData[42].storeId, 'mlay');
      expect(Coupon.mockData[43].storeId, 'laveen');
      expect(Coupon.mockData[44].storeId, 'ayworlds');
      expect(Coupon.mockData[45].storeId, 'qzs');
    });

    test('toFirestoreMap contains required fields', () {
      final coupon = Coupon(
        id: 'test',
        code: 'FLASH50',
        storeId: 'jarir',
        storeName: 'Jarir',
        discountLabel: '50% off',
        discountPercent: 50,
        expiresAt: DateTime(2026, 6, 15),
      );

      final map = coupon.toFirestoreMap();

      expect(map['code'], 'FLASH50');
      expect(map['storeId'], 'jarir');
      expect(map['discountPercent'], 50);
      expect(map['active'], true);
    });
  });
}
