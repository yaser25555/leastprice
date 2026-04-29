import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdBannerItem {
  const AdBannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.targetUrl,
    required this.storeName,
    required this.active,
    required this.order,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetUrl;
  final String storeName;
  final bool active;
  final int order;

  AdBannerItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? targetUrl,
    String? storeName,
    bool? active,
    int? order,
  }) {
    return AdBannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      storeName: storeName ?? this.storeName,
      active: active ?? this.active,
      order: order ?? this.order,
    );
  }

  factory AdBannerItem.fromJson(Map<String, dynamic> json) {
    return AdBannerItem(
      id: stringValue(json['id']) ?? '',
      title: stringValue(json['title']) ?? tr('عرض متجر', 'Store offer'),
      subtitle: stringValue(json['subtitle']) ??
          tr(
            'خصومات يومية داخل أرخص سعر',
            'Daily discounts inside LeastPrice',
          ),
      imageUrl: normalizedImageUrl(
        stringValue(json['imageUrl']) ?? '',
        fallbackLabel: stringValue(json['title']) ?? 'LeastPrice Banner',
      ),
      targetUrl: stringValue(json['targetUrl']) ??
          LeastPriceDataConfig.adminWhatsAppUrl,
      storeName: stringValue(json['storeName']) ??
          tr('متجر متعاقد', 'Partner store'),
      active: boolValue(json['active'], defaultValue: true),
      order: intValue(json['order']),
    );
  }

  factory AdBannerItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return AdBannerItem.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl.trim().isEmpty
          ? LeastPriceDataConfig.adminWhatsAppUrl
          : targetUrl,
      'storeName': storeName,
      'active': active,
      'order': order,
    };
  }

  static List<AdBannerItem> get mockData => [
        AdBannerItem(
          id: 'local-roaster',
          title: tr('عرض المحمصة المميزة',
              'Featured roastery offer'),
          subtitle: tr(
            'خصم على القهوة المختصة وحبوب اليوم مع توصيل سريع.',
            'Discount on specialty coffee and today?s beans with fast delivery.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1400&q=80',
          targetUrl: LeastPriceDataConfig.adminWhatsAppUrl,
          storeName: tr('محمصة الشرقية', 'Eastern Roastery'),
          active: true,
          order: 1,
        ),
        AdBannerItem(
          id: 'restaurant-partner',
          title: tr('وجبات محلية بسعر أفضل',
              'Local meals at a better price'),
          subtitle: tr(
            'عروض حصرية من مطاعم الخبر والدمام داخل التطبيق.',
            'Exclusive offers from Khobar and Dammam restaurants inside the app.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1400&q=80',
          targetUrl: LeastPriceDataConfig.adminWhatsAppUrl,
          storeName: tr('شركاء المطاعم', 'Restaurant partners'),
          active: true,
          order: 2,
        ),
      ];
}
