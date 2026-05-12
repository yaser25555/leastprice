import 'package:flutter_test/flutter_test.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';

void main() {
  group('AdBannerItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'banner-1',
        'title': 'عرض الأسبوع',
        'subtitle': 'خصم يصل إلى 50%',
        'imageUrl': 'https://example.com/banner.jpg',
        'targetUrl': 'https://wa.me/966500000000',
        'storeName': 'متجر تجريبي',
        'active': true,
        'order': 1,
      };

      final banner = AdBannerItem.fromJson(json);

      expect(banner.id, 'banner-1');
      expect(banner.title, 'عرض الأسبوع');
      expect(banner.subtitle, 'خصم يصل إلى 50%');
      expect(banner.targetUrl, 'https://wa.me/966500000000');
      expect(banner.storeName, 'متجر تجريبي');
      expect(banner.active, true);
      expect(banner.order, 1);
    });

    test('fromJson handles empty data with defaults', () {
      final banner = AdBannerItem.fromJson({});

      expect(banner.title, isNotEmpty);
      expect(banner.subtitle, isNotEmpty);
      expect(banner.storeName, isNotEmpty);
      expect(banner.active, true);
      expect(banner.order, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final banner = AdBannerItem(
        id: 'b1',
        title: 'Title',
        subtitle: 'Sub',
        imageUrl: 'https://example.com/img.jpg',
        targetUrl: 'https://example.com',
        storeName: 'Store',
        active: true,
        order: 1,
      );

      final updated = banner.copyWith(order: 5);

      expect(updated.id, 'b1');
      expect(updated.title, 'Title');
      expect(updated.order, 5);
      expect(updated.active, true);
    });

    test('toFirestoreMap contains required fields', () {
      final banner = AdBannerItem(
        id: 'b1',
        title: 'Banner',
        subtitle: 'Subtitle',
        imageUrl: 'https://example.com/img.jpg',
        targetUrl: 'https://example.com/go',
        storeName: 'Test Store',
        active: true,
        order: 3,
      );

      final map = banner.toFirestoreMap();

      expect(map['title'], 'Banner');
      expect(map['subtitle'], 'Subtitle');
      expect(map['active'], true);
      expect(map['order'], 3);
      expect(map['targetUrl'], 'https://example.com/go');
    });
  });
}
