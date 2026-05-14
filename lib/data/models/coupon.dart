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
      title: tr('كوبون روشن لتذاكر كاس العالم', 'Exclusive Roshen World Cup coupon'),
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
    Coupon(
      id: 'coupon-qatret-asal',
      code: 'F-P3XPV',
      storeId: 'qatret-asal',
      storeName: tr('قطرة عسل', 'Qatret Asal'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون قطرة عسل الحصري', 'Exclusive Qatret Asal coupon'),
      description: tr(
        'كود خصم على العسل والمنتجات الطبيعية.',
        'Discount code for honey and natural products.',
      ),
    ),
    Coupon(
      id: 'coupon-itsmine',
      code: 'F-Q2HLV',
      storeId: 'itsmine',
      storeName: tr('اتزماين', 'Itsmine'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون اتزماين الحصري', 'Exclusive Itsmine coupon'),
      description: tr(
        'كود خصم على الأزياء النسائية.',
        'Discount code for women\'s fashion.',
      ),
    ),
    Coupon(
      id: 'coupon-goldlolwa-1',
      code: 'F-Y520I',
      storeId: 'goldlolwa',
      storeName: tr('لمعة اللؤلؤة', 'Gold Lolwa'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون لمعة اللؤلؤة الحصري', 'Exclusive Gold Lolwa coupon'),
      description: tr(
        'كود خصم على المشغولات الذهبية.',
        'Discount code for gold jewelry.',
      ),
    ),
    Coupon(
      id: 'coupon-goldlolwa-2',
      code: 'F-L0DGK',
      storeId: 'goldlolwa',
      storeName: tr('لمعة اللؤلؤة', 'Gold Lolwa'),
      discountLabel: tr('خصم إضافي', 'Extra discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون لمعة اللؤلؤة الإضافي', 'Exclusive Gold Lolwa extra coupon'),
      description: tr(
        'كود خصم إضافي على المشغولات الذهبية.',
        'Extra discount code for gold jewelry.',
      ),
    ),
    Coupon(
      id: 'coupon-algharbi',
      code: 'F-GBVHF',
      storeId: 'algharbi',
      storeName: tr('الغربي', 'Al-Gharbi'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون الغربي الحصري', 'Exclusive Al-Gharbi coupon'),
      description: tr(
        'كود خصم على المكسرات والبهارات والعسل.',
        'Discount code for nuts, spices, and honey.',
      ),
    ),
    Coupon(
      id: 'coupon-mshkatmran',
      code: 'F-XUQOU',
      storeId: 'mshkatmran',
      storeName: tr('مشكاة مران', 'Mshkat Mran'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون مشكاة مران الحصري', 'Exclusive Mshkat Mran coupon'),
      description: tr(
        'كود خصم على زيت الزيتون الطبيعي.',
        'Discount code for natural olive oil.',
      ),
    ),
    Coupon(
      id: 'coupon-threeq',
      code: 'F-VVDLU',
      storeId: 'threeq',
      storeName: tr('ثلاث أرباع', '3Q'),
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ثلاث أرباع الحصري', 'Exclusive 3Q coupon'),
      description: tr(
        'كود خصم على الأجهزة الكهربائية والإلكترونيات.',
        'Discount code for electronics and home appliances.',
      ),
    ),
    Coupon(
      id: 'coupon-swanky',
      code: 'F-3YNKY',
      storeId: 'swanky',
      storeName: 'SWANKY',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون SWANKY الحصري', 'Exclusive SWANKY coupon'),
      description: tr(
        'كود خصم على آلات صنع القهوة.',
        'Discount code for coffee machines.',
      ),
    ),
    Coupon(
      id: 'coupon-shaving360',
      code: 'F-8VSNU',
      storeId: 'shaving360',
      storeName: 'Shaving360',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون Shaving360 الحصري', 'Exclusive Shaving360 coupon'),
      description: tr(
        'كود خصم على شنط وأدوات الحلاقة.',
        'Discount code for shaving kits and tools.',
      ),
    ),
    Coupon(
      id: 'coupon-mtjr',
      code: 'F-NATRS',
      storeId: 'mtjr',
      storeName: 'ليدرز',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ليدرز الحصري', 'Exclusive Leaders coupon'),
      description: tr(
        'كود خصم على كراسي مكتبية وقيمنق.',
        'Discount code for office and gaming chairs.',
      ),
    ),
    Coupon(
      id: 'coupon-smarthub1',
      code: 'F-AJAOZ',
      storeId: 'smarthub1',
      storeName: 'سمارت هب 1',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون سمارت هب 1 الحصري', 'Exclusive Smart Hub 1 coupon'),
      description: tr(
        'كود خصم على كاميرات المراقبة الذكية.',
        'Discount code for smart security cameras.',
      ),
    ),
    Coupon(
      id: 'coupon-ragroastery',
      code: 'F-6MKX8',
      storeId: 'ragroastery',
      storeName: 'RAG Roastery',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون RAG Roastery الحصري', 'Exclusive RAG Roastery coupon'),
      description: tr(
        'كود خصم على القهوة المختصة.',
        'Discount code for specialty coffee.',
      ),
    ),
    Coupon(
      id: 'coupon-rakla',
      code: 'F-MPHEO',
      storeId: 'rakla',
      storeName: 'ركله',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ركله الحصري', 'Exclusive Rakla coupon'),
      description: tr(
        'كود خصم على التيشيرتات الرياضية.',
        'Discount code for sports jerseys.',
      ),
    ),
    Coupon(
      id: 'coupon-burgundy',
      code: 'F-EGNRF',
      storeId: 'burgundy',
      storeName: 'Burgundy',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون Burgundy الحصري', 'Exclusive Burgundy coupon'),
      description: tr(
        'كود خصم على المجوهرات والألماس.',
        'Discount code for jewellery and diamonds.',
      ),
    ),
    Coupon(
      id: 'coupon-takecard',
      code: 'F-S8ZKN',
      storeId: 'takecard',
      storeName: 'Take Card',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون Take Card الحصري', 'Exclusive Take Card coupon'),
      description: tr(
        'كود خصم على البطاقات الرقمية والألعاب.',
        'Discount code for digital cards and games.',
      ),
    ),
    Coupon(
      id: 'coupon-sadacards',
      code: 'F-PSLOS',
      storeId: 'sadacards',
      storeName: 'سدا كاردز',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون سدا كاردز الحصري', 'Exclusive Sada Cards coupon'),
      description: tr(
        'كود خصم على بطاقات ايوا.',
        'Discount code for Aywa cards.',
      ),
    ),
    Coupon(
      id: 'coupon-alanood',
      code: 'F-EQEZ5',
      storeId: 'alanood',
      storeName: 'العنود للأزياء',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون العنود للأزياء الحصري', 'Exclusive Al Anood Fashion coupon'),
      description: tr(
        'كود خصم على فساتين السهرة والمناسبات.',
        'Discount code for evening and occasion dresses.',
      ),
    ),
    Coupon(
      id: 'coupon-herfitness',
      code: 'F-C3ZLB',
      storeId: 'herfitness',
      storeName: 'Her Fitness',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون Her Fitness الحصري', 'Exclusive Her Fitness coupon'),
      description: tr(
        'كود خصم على الاشتراكات الرياضية والتدريب الشخصي.',
        'Discount code for gym memberships and personal training.',
      ),
    ),
    Coupon(
      id: 'coupon-eseven',
      code: 'F-YA26G',
      storeId: 'eseven',
      storeName: 'E-SEVEN STORE',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون E-SEVEN الحصري', 'Exclusive E-SEVEN coupon'),
      description: tr(
        'كود خصم على العطور والأحذية والمجوهرات.',
        'Discount code for perfumes, shoes, and jewellery.',
      ),
    ),
    Coupon(
      id: 'coupon-cozmazone',
      code: 'F-WHTWM',
      storeId: 'cozmazone',
      storeName: 'كوزمازون',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون كوزمازون الحصري', 'Exclusive Cozmazone coupon'),
      description: tr(
        'كود خصم على الكولاجين ومنتجات التجميل.',
        'Discount code for collagen and beauty products.',
      ),
    ),
    Coupon(
      id: 'coupon-bckyrdbbq',
      code: 'F-OLKAL',
      storeId: 'bckyrdbbq',
      storeName: 'عالم الشواء',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون عالم الشواء الحصري', 'Exclusive Bckyrd BBQ coupon'),
      description: tr(
        'كود خصم على الشوايات والسموكرات.',
        'Discount code for grills and smokers.',
      ),
    ),
    Coupon(
      id: 'coupon-freesia',
      code: 'F-P42C9',
      storeId: 'freesia',
      storeName: 'فريسيا',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون فريسيا الحصري', 'Exclusive Freesia coupon'),
      description: tr(
        'كود خصم على مستلزمات العناية والمكياج والعطور.',
        'Discount code for skincare, makeup, and perfumes.',
      ),
    ),
    Coupon(
      id: 'coupon-kilmananoud',
      code: 'F-PAM48',
      storeId: 'kilmananoud',
      storeName: 'كلمنتان للعود',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون كلمنتان للعود الحصري', 'Exclusive Kilmantan Oud coupon'),
      description: tr(
        'كود خصم على العود والكهرمان.',
        'Discount code for oud and amber.',
      ),
    ),
    Coupon(
      id: 'coupon-worldgivenchy',
      code: 'F-XH9D4',
      storeId: 'worldgivenchy',
      storeName: 'عالم جيفنشي',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون عالم جيفنشي الحصري', 'Exclusive World Givenchy coupon'),
      description: tr(
        'كود خصم على العطور الأصلية والنيش.',
        'Discount code for original and niche perfumes.',
      ),
    ),
    Coupon(
      id: 'coupon-bkam',
      code: 'F-KIWV7',
      storeId: 'bkam',
      storeName: 'بكم',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون بكم الحصري', 'Exclusive Bkam coupon'),
      description: tr(
        'كود خصم على جميع المنتجات.',
        'Discount code for all products.',
      ),
    ),
    Coupon(
      id: 'coupon-retskin-1',
      code: 'F-ZVAH1',
      storeId: 'retskin',
      storeName: 'ريتسكين',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ريتسكين الحصري', 'Exclusive Retskin coupon'),
      description: tr(
        'كود خصم على أجهزة الليزر المنزلي.',
        'Discount code for home laser devices.',
      ),
    ),
    Coupon(
      id: 'coupon-retskin-2',
      code: 'F-MHKD4',
      storeId: 'retskin',
      storeName: 'ريتسكين',
      discountLabel: tr('خصم إضافي', 'Extra discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ريتسكين الإضافي', 'Exclusive Retskin extra coupon'),
      description: tr(
        'كود خصم إضافي على أجهزة الليزر المنزلي.',
        'Extra discount code for home laser devices.',
      ),
    ),
    Coupon(
      id: 'coupon-madyalteb',
      code: 'F-GH6Q8',
      storeId: 'madyalteb',
      storeName: 'ماضي الطيب',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ماضي الطيب الحصري', 'Exclusive Mady Alteb coupon'),
      description: tr(
        'كود خصم على العود والبخور والعطور.',
        'Discount code for oud, incense, and perfumes.',
      ),
    ),
    Coupon(
      id: 'coupon-marsil',
      code: 'F-U5Y3A',
      storeId: 'marsil',
      storeName: 'مارسيل',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون مارسيل الحصري', 'Exclusive Marsil coupon'),
      description: tr(
        'كود خصم على الفساتين وملابس الأطفال.',
        'Discount code for dresses and children\'s clothing.',
      ),
    ),
    Coupon(
      id: 'coupon-almoqtas',
      code: 'F-MOKTAS',
      storeId: 'almoqtas',
      storeName: 'المختص',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون المختص الحصري', 'Exclusive Almoqtas coupon'),
      description: tr(
        'كود خصم على الشوزات والسنيكرز الرجالية والنسائية.',
        'Discount code for men\'s and women\'s shoes and sneakers.',
      ),
    ),
    Coupon(
      id: 'coupon-mlay',
      code: 'F-AUFM8',
      storeId: 'mlay',
      storeName: 'ملاي',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون ملاي الحصري', 'Exclusive Mlay coupon'),
      description: tr(
        'كود خصم على أجهزة الليزر المنزلي.',
        'Discount code for home laser devices.',
      ),
    ),
    Coupon(
      id: 'coupon-laveen',
      code: 'F-FIYZ9',
      storeId: 'laveen',
      storeName: 'لاڤين عباية',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون لاڤين عباية الحصري', 'Exclusive Laveen Abaya coupon'),
      description: tr(
        'كود خصم على العبايات والبليزرات.',
        'Discount code for abayas and blazers.',
      ),
    ),
    Coupon(
      id: 'coupon-ayworlds',
      code: 'F-8QU60',
      storeId: 'ayworlds',
      storeName: 'عالم ايوا',
      discountLabel: tr('خصم خاص', 'Special discount'),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      title: tr('كوبون عالم ايوا الحصري', 'Exclusive Aywa World coupon'),
      description: tr(
        'كود خصم على بطاقات الشحن والمنتجات الرقمية.',
        'Discount code for recharge cards and digital products.',
      ),
    ),
  ];
}
