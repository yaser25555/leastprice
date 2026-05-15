import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/seed/salla_affiliate_seed.dart';

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
    this.storeLogoUrl,
    this.storeUrl,
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
  final String? storeLogoUrl;
  final String? storeUrl;

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
    String? storeLogoUrl,
    String? storeUrl,
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
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    final code = stringValue(json['code'])?.trim() ?? '';
    final storeName = stringValue(json['storeName'])?.trim() ?? '';
    final rawStoreId = (stringValue(json['storeId']) ??
            inferStoreIdFromUrl('', fallbackName: storeName) ??
            '')
        .trim();
    final storeId = rawStoreId.startsWith('salla-')
        ? rawStoreId
        : normalizeStoreIdToken(rawStoreId);
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
      storeLogoUrl:
          stringValue(json['storeLogoUrl'] ?? json['logoUrl'])?.trim(),
      storeUrl: stringValue(json['storeUrl'] ?? json['url'])?.trim(),
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
      if (storeLogoUrl != null && storeLogoUrl!.trim().isNotEmpty)
        'storeLogoUrl': storeLogoUrl,
      if (storeUrl != null && storeUrl!.trim().isNotEmpty) 'storeUrl': storeUrl,
    };
  }

  static Coupon _fromSallaAffiliateSeed(Map<String, Object?> store) {
    final discountPercent = _parseDiscountPercent(store['discountPercent']);
    final name = stringValue(store['name']) ?? '';
    final nameEn = stringValue(store['nameEn']) ?? name;

    return Coupon(
      id: 'coupon-${stringValue(store['id'])}',
      code: stringValue(store['couponCode'])?.trim() ?? '',
      storeId: stringValue(store['id']) ?? '',
      storeName: name,
      discountLabel: tr(
        stringValue(store['discountLabelAr']) ?? 'خصم إضافي',
        stringValue(store['discountLabelEn']) ?? 'Extra discount',
      ),
      discountPercent: discountPercent,
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr(
        'كوبون $name',
        'Exclusive coupon from $nameEn',
      ),
      description: tr(
        'انسخ الكود واستخدمه عند إتمام الطلب عبر رابط المتجر.',
        'Copy the code and use it at checkout through the store link.',
      ),
      storeLogoUrl: stringValue(store['logoUrl'])?.trim(),
      storeUrl: stringValue(store['url'])?.trim(),
    );
  }

  static String _storeNameForId(String storeId) {
    switch (storeId) {
      case 'amazon':
        return 'Amazon';
      case 'noon':
        return 'Noon';
      case 'namshi':
        return 'Namshi';
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
      case 'dar-al-amirat':
        return tr('دار الأميرات', 'Dar Al-Amirat');
      case 'kabsh-najd':
        return tr('اضاحي كبش نجد', 'Kabsh Najd');
      case 'vanier':
        return tr('ڤانير', 'Vanier');
      case 'rashfa-dhikra':
        return tr('رشفة ذكرى', 'Rashfa Dhikra');
      case 'roshen':
        return tr('روشن', 'Roshen');
      case 'roshen-tickets':
        return tr('روشن تذاكر كاس العالم', 'Roshen World Cup Tickets');
      case 'al-reem':
        return tr('الريم للعبايات', 'Al-Reem Abayas');
      case 'vibe':
        return tr('فايب', 'Vibe');
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
      id: 'coupon-noon-mzxpw',
      code: 'MZXPW',
      storeId: 'noon',
      storeName: 'Noon',
      discountLabel: tr('خصم حتى ٢٠%', 'Up to 20% off'),
      discountPercent: 20,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      title: tr('كوبون نون الحصري', 'Exclusive Noon coupon'),
      description: tr(
        'انسخ الكود MZXPW واستخدمه عند إتمام الطلب.',
        'Copy code MZXPW and use it at checkout.',
      ),
    ),
    Coupon(
      id: 'coupon-noon-ttbze',
      code: 'TTBZE',
      storeId: 'noon',
      storeName: 'Noon',
      discountLabel: tr('خصم حتى ١٥%', 'Up to 15% off'),
      discountPercent: 15,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      title: tr('كوبون نون الحصري', 'Exclusive Noon coupon'),
      description: tr(
        'انسخ الكود TTBZE واستخدمه عند إتمام الطلب.',
        'Copy code TTBZE and use it at checkout.',
      ),
    ),
    Coupon(
      id: 'coupon-noon-ndz190',
      code: 'NDZ190',
      storeId: 'noon',
      storeName: 'Noon',
      discountLabel: tr('خصم إضافي حصري', 'Exclusive Extra Discount'),
      discountPercent: 10,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      title: tr('كوبون نون المعتمد', 'Verified Noon coupon'),
      description: tr(
        'انسخ الكود NDZ190 واستخدمه للحصول على أفضل توفير متاح.',
        'Copy code NDZ190 and use it for the best available savings.',
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
    Coupon(
      id: 'coupon-dar-al-amirat',
      code: 'F-URT3J',
      storeId: 'dar-al-amirat',
      storeName: tr('دار الأميرات', 'Dar Al-Amirat'),
      discountLabel: tr('خصم إضافي', 'Extra discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون دار الأميرات الحصري', 'Exclusive Dar Al-Amirat coupon'),
      description: tr(
        'انسخ الكود واستخدمه للحصول على خصم إضافي عند الدفع.',
        'Copy the code and use it at checkout for an extra discount.',
      ),
    ),
    Coupon(
      id: 'coupon-kabsh-najd',
      code: 'F-EMYFS',
      storeId: 'kabsh-najd',
      storeName: tr('اضاحي كبش نجد', 'Kabsh Najd'),
      discountLabel: tr('عرض خاص', 'Special offer'),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      title: tr('كوبون كبش نجد للحوم', 'Exclusive Kabsh Najd coupon'),
      description: tr(
        'وفر أكثر عند طلب الذبائح والأضاحي عبر التطبيق.',
        'Save more on livestock and meat orders via the app.',
      ),
    ),
    Coupon(
      id: 'coupon-vanier',
      code: 'F-NEEM0',
      storeId: 'vanier',
      storeName: tr('ڤانير', 'Vanier'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ڤانير الحصري', 'Exclusive Vanier coupon'),
      description: tr(
        'كود خصم على منتجات العناية و المكياج و العطور.',
        'Discount code for skincare, makeup & perfume products.',
      ),
    ),
    Coupon(
      id: 'coupon-rashfa-dhikra',
      code: 'F-JWEJF',
      storeId: 'rashfa-dhikra',
      storeName: tr('رشفة ذكرى', 'Rashfa Dhikra'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون رشفة ذكرى الحصري', 'Exclusive Rashfa Dhikra coupon'),
      description: tr(
        'كود خصم على العطور.',
        'Discount code for perfumes.',
      ),
    ),
    Coupon(
      id: 'coupon-roshen',
      code: 'F-TKFG7',
      storeId: 'roshen',
      storeName: tr('روشن', 'Roshen'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون روشن الحصري', 'Exclusive Roshen coupon'),
      description: tr(
        'كود خصم على الألبسة.',
        'Discount code for clothing.',
      ),
    ),
    Coupon(
      id: 'coupon-roshen-tickets',
      code: 'F-Z3K4V',
      storeId: 'roshen-tickets',
      storeName: tr('روشن تذاكر كاس العالم', 'Roshen World Cup Tickets'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr(
          'كوبون روشن لتذاكر كاس العالم', 'Exclusive Roshen World Cup coupon'),
      description: tr(
        'كود خصم على تذاكر كاس العالم.',
        'Discount code for World Cup tickets.',
      ),
    ),
    Coupon(
      id: 'coupon-al-reem',
      code: 'F-HZWMZ',
      storeId: 'al-reem',
      storeName: tr('الريم للعبايات', 'Al-Reem Abayas'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون الريم للعبايات الحصري', 'Exclusive Al-Reem coupon'),
      description: tr(
        'كود خصم على العبايات.',
        'Discount code for abayas.',
      ),
    ),
    Coupon(
      id: 'coupon-vibe',
      code: 'F-ISGIW',
      storeId: 'vibe',
      storeName: tr('فايب', 'Vibe'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون فايب الحصري', 'Exclusive Vibe coupon'),
      description: tr(
        'كود خصم على الساعات والاكسسوارات.',
        'Discount code for watches and accessories.',
      ),
    ),
    ...SallaAffiliateSeed.stores
        .where((store) =>
            (stringValue(store['couponCode'])?.trim().isNotEmpty ?? false))
        .map(_fromSallaAffiliateSeed),
  ];
}
