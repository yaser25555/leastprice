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
  });

  final String id;
  final String title;
  final String imageUrl;
  final double beforePrice;
  final double afterPrice;
  final DateTime expiryDate;
  final bool active;

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
  }) {
    return ExclusiveDeal(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      beforePrice: beforePrice ?? this.beforePrice,
      afterPrice: afterPrice ?? this.afterPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      active: active ?? this.active,
    );
  }

  factory ExclusiveDeal.fromJson(Map<String, dynamic> json) {
    final expiryDate =
        dateTimeValue(json['expiry_date'] ?? json['expiryDate']) ??
            DateTime.now().add(const Duration(days: 1));

    return ExclusiveDeal(
      id: stringValue(json['id']) ?? '',
      title:
          stringValue(json['title']) ?? tr('عرض حصري', 'Exclusive deal'),
      imageUrl: normalizedImageUrl(
        stringValue(json['imageUrl']) ?? '',
        fallbackLabel: stringValue(json['title']) ?? 'Exclusive Deal',
      ),
      beforePrice: doubleValue(json['beforePrice'] ?? json['price_before']),
      afterPrice: doubleValue(json['afterPrice'] ?? json['price_after']),
      expiryDate: expiryDate,
      active: boolValue(json['active'], defaultValue: true),
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
    };
  }

  static final List<ExclusiveDeal> mockData = [
    ExclusiveDeal(
      id: 'deal-1',
      title: tr('عرض محمصة نهاية الأسبوع',
          'Weekend roastery deal'),
      imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      beforePrice: 42,
      afterPrice: 29,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
    ),
    ExclusiveDeal(
      id: 'deal-2',
      title: tr('عرض عناية يومي من الصيدلية',
          'Daily pharmacy care deal'),
      imageUrl:
          'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=900&q=80',
      beforePrice: 79,
      afterPrice: 52,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
    ),
  ];
}
