import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/utils/helpers.dart';

class ExclusiveDeal {
  const ExclusiveDeal({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.beforePrice,
    required this.afterPrice,
    required this.expiryDate,
    this.active = true,
    this.createdByUid = '',
    this.createdByEmail = '',
    this.lastUpdatedByUid = '',
    this.lastUpdatedByEmail = '',
    this.dealUrl = '',
  });

  final String id;
  final String title;
  final String imageUrl;
  final double beforePrice;
  final double afterPrice;
  final DateTime expiryDate;
  final bool active;
  final String createdByUid;
  final String createdByEmail;
  final String lastUpdatedByUid;
  final String lastUpdatedByEmail;
  final String dealUrl;

  double get savingsAmount => beforePrice - afterPrice;

  int get savingsPercent {
    if (beforePrice <= 0) {
      return 0;
    }

    return (((beforePrice - afterPrice) / beforePrice).clamp(0.0, 1.0) * 100)
        .round();
  }

  bool isExpiredAt(DateTime dateTime) => !expiryDate.isAfter(dateTime);

  bool get isExpired => isExpiredAt(DateTime.now());

  ExclusiveDeal copyWith({
    String? id,
    String? title,
    String? imageUrl,
    double? beforePrice,
    double? afterPrice,
    DateTime? expiryDate,
    bool? active,
    String? createdByUid,
    String? createdByEmail,
    String? lastUpdatedByUid,
    String? lastUpdatedByEmail,
    String? dealUrl,
  }) {
    return ExclusiveDeal(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      beforePrice: beforePrice ?? this.beforePrice,
      afterPrice: afterPrice ?? this.afterPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      active: active ?? this.active,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      lastUpdatedByUid: lastUpdatedByUid ?? this.lastUpdatedByUid,
      lastUpdatedByEmail: lastUpdatedByEmail ?? this.lastUpdatedByEmail,
      dealUrl: dealUrl ?? this.dealUrl,
    );
  }

  factory ExclusiveDeal.fromJson(Map<String, dynamic> json) {
    final expiryDate =
        dateTimeValue(json['expiry_date'] ?? json['expiryDate']) ??
            DateTime.now().add(const Duration(days: 1));

    return ExclusiveDeal(
      id: stringValue(json['id']) ?? '',
      title: stringValue(json['title']) ?? tr('عرض حصري', 'Exclusive deal'),
      imageUrl: normalizedImageUrl(
        stringValue(json['imageUrl']) ?? '',
        fallbackLabel: stringValue(json['title']) ?? 'Exclusive Deal',
      ),
      beforePrice: doubleValue(json['beforePrice'] ?? json['price_before']),
      afterPrice: doubleValue(json['afterPrice'] ?? json['price_after']),
      expiryDate: expiryDate,
      active: boolValue(json['active'], defaultValue: true),
      createdByUid: stringValue(json['createdByUid']) ?? '',
      createdByEmail: stringValue(json['createdByEmail']) ?? '',
      lastUpdatedByUid: stringValue(json['lastUpdatedByUid']) ?? '',
      lastUpdatedByEmail: stringValue(json['lastUpdatedByEmail']) ?? '',
      dealUrl: stringValue(json['dealUrl']) ?? '',
    );
  }

  factory ExclusiveDeal.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ExclusiveDeal.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'beforePrice': beforePrice,
      'afterPrice': afterPrice,
      'expiry_date': Timestamp.fromDate(expiryDate),
      'active': active,
      if (createdByUid.trim().isNotEmpty) 'createdByUid': createdByUid.trim(),
      if (createdByEmail.trim().isNotEmpty)
        'createdByEmail': createdByEmail.trim().toLowerCase(),
      if (lastUpdatedByUid.trim().isNotEmpty)
        'lastUpdatedByUid': lastUpdatedByUid.trim(),
      if (lastUpdatedByEmail.trim().isNotEmpty)
        'lastUpdatedByEmail': lastUpdatedByEmail.trim().toLowerCase(),
      if (dealUrl.trim().isNotEmpty) 'dealUrl': dealUrl.trim(),
    };
  }

  static final List<ExclusiveDeal> mockData = [
    ExclusiveDeal(
      id: 'mock_deal_1',
      title: 'عرض حصري على سامسونج جالكسي S24',
      imageUrl: 'https://images.unsplash.com/photo-1610945264803-c22b62d2a7b3?q=80&w=1000&auto=format&fit=crop',
      beforePrice: 5000,
      afterPrice: 4500,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      active: true,
      dealUrl: 'https://panda.com.sa',
    ),
    ExclusiveDeal(
      id: 'mock_deal_2',
      title: 'خصم 20% على منتجات أبل',
      imageUrl: 'https://images.unsplash.com/photo-1611186871348-b1f696febbb3?q=80&w=1000&auto=format&fit=crop',
      beforePrice: 3000,
      afterPrice: 2400,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      active: true,
      dealUrl: 'https://extra.com',
    ),
    ExclusiveDeal(
      id: 'dar_al_amirat_deal',
      title: 'دار الأميرات - أكبر تجمع لمنتجات العناية',
      imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc4033c8?q=80&w=1000&auto=format&fit=crop',
      beforePrice: 0,
      afterPrice: 0,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      active: true,
      dealUrl: 'https://mtjr.at/FN2AIl2KWs',
    ),
    ExclusiveDeal(
      id: 'kabsh_najd_deal',
      title: 'أضاحي كبش نجد - جودة ومصداقية',
      imageUrl: 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?q=80&w=1000&auto=format&fit=crop',
      beforePrice: 0,
      afterPrice: 0,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      active: true,
      dealUrl: 'https://mtjr.at/_2-N8J8JYq',
    ),
  ];
}
