import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/utils/helpers.dart';

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.storeId,
    required this.storeName,
    required this.discountLabel,
    required this.expiresAt,
    this.discountPercent,
    this.active = true,
    this.title,
    this.description,
  });

  final String id;
  final String code;
  final String storeId;
  final String storeName;
  final String discountLabel;
  final DateTime expiresAt;
  final double? discountPercent;
  final bool active;
  final String? title;
  final String? description;

  bool isExpiredAt(DateTime dateTime) => !expiresAt.isAfter(dateTime);

  bool get isExpired => isExpiredAt(DateTime.now());

  bool get isSupportedFeaturedStore => storeId.trim().isNotEmpty;

  Coupon copyWith({
    String? id,
    String? code,
    String? storeId,
    String? storeName,
    String? discountLabel,
    DateTime? expiresAt,
    double? discountPercent,
    bool? active,
    String? title,
    String? description,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      discountLabel: discountLabel ?? this.discountLabel,
      expiresAt: expiresAt ?? this.expiresAt,
      discountPercent: discountPercent ?? this.discountPercent,
      active: active ?? this.active,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    final code = stringValue(json['code'])?.trim() ?? '';
    final storeName = stringValue(json['storeName'])?.trim() ?? '';
    final storeId = normalizeStoreIdToken(
      stringValue(json['storeId']) ??
          inferStoreIdFromUrl('', fallbackName: storeName) ??
          '',
    );
    final discountLabel =
        stringValue(json['discountLabel'] ?? json['discount'])?.trim() ?? '';
    final discountPercent = _parseDiscountPercent(
      json['discountPercent'] ?? json['discount'] ?? discountLabel,
    );

    return Coupon(
      id: stringValue(json['id'])?.trim() ?? '',
      code: code,
      storeId: storeId,
      storeName: storeName.isNotEmpty ? storeName : _storeNameForId(storeId),
      discountLabel: discountLabel.isNotEmpty
          ? discountLabel
          : _discountLabelForPercent(discountPercent),
      expiresAt: dateTimeValue(json['expiresAt'] ?? json['expiryDate']) ??
          DateTime.now().add(const Duration(days: 30)),
      discountPercent: discountPercent,
      active: boolValue(json['active'], defaultValue: true),
      title: stringValue(json['title'])?.trim(),
      description: stringValue(json['description'])?.trim(),
    );
  }

  factory Coupon.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document) {
    return Coupon.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'code': code,
      'storeId': storeId,
      'storeName': storeName,
      'discountLabel': discountLabel,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'active': active,
      if (title != null && title!.trim().isNotEmpty) 'title': title,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
    };
  }

  static String _storeNameForId(String storeId) {
    switch (storeId) {
      case 'amazon':
        return 'Amazon';
      case 'noon':
        return 'Noon';
      case 'namshi':
        return 'Namshi';
      case 'iherb':
        return 'iHerb';
      case 'sephora':
        return 'Sephora';
      case 'shein':
        return 'SHEIN';
      case 'jarir':
        return 'Jarir';
      case 'extra':
        return 'Extra';
      case 'nahdi':
        return tr('النهدي', 'Nahdi');
      case 'aldawaa':
        return tr('الدواء', 'Al-Dawaa');
      case 'lulu':
        return tr('لولو', 'Lulu');
      case 'carrefour':
        return 'Carrefour';
      case 'panda':
        return tr('بنده', 'Panda');
      case 'othaim':
        return tr('العثيم', 'Othaim');
      case 'tamimi':
        return tr('التميمي', 'Tamimi');
      default:
        return tr('متجر إلكتروني', 'Online store');
    }
  }

  static String _discountLabelForPercent(double? discountPercent) {
    if (discountPercent == null || discountPercent <= 0) {
      return tr('خصم خاص', 'Special discount');
    }
    final normalized = discountPercent % 1 == 0
        ? discountPercent.toStringAsFixed(0)
        : discountPercent.toStringAsFixed(1);
    return tr('خصم $normalized%', '$normalized% off');
  }

  static double? _parseDiscountPercent(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is num) {
      return rawValue.toDouble();
    }

    final normalized = rawValue.toString().replaceAll(',', '.').trim();
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(1)!);
  }

  static final List<Coupon> mockData = [
    Coupon(
      id: 'coupon-noon',
      code: 'EAST15',
      storeId: 'noon',
      storeName: 'Noon',
      discountLabel: '15% off',
      discountPercent: 15,
      expiresAt: DateTime.now().add(const Duration(days: 10)),
      title: tr('كوبون نون الحصري', 'Exclusive Noon coupon'),
      description: tr(
        'انسخ الكود واستخدمه عند إتمام الطلب.',
        'Copy the code and use it at checkout.',
      ),
    ),
    Coupon(
      id: 'coupon-namshi',
      code: 'STYLE20',
      storeId: 'namshi',
      storeName: 'Namshi',
      discountLabel: '20% off',
      discountPercent: 20,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      title: tr('كوبون نمشي الحصري', 'Exclusive Namshi coupon'),
      description: tr(
        'وفر أكثر على مشتريات الأزياء والعناية.',
        'Save more on fashion and beauty orders.',
      ),
    ),
  ];
}
