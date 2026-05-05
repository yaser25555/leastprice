import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ProductComparison {
  const ProductComparison({
    this.documentId,
    required this.categoryId,
    required this.categoryLabel,
    required this.expensiveName,
    required this.expensivePrice,
    required this.expensiveImageUrl,
    required this.alternativeName,
    required this.alternativePrice,
    required this.alternativeImageUrl,
    required this.buyUrl,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    this.isAutomated = true,
    this.fragranceNotes,
    this.activeIngredients,
    this.localLocationLabel,
    this.localLocationUrl,
  });

  final String? documentId;
  final String categoryId;
  final String categoryLabel;
  final String expensiveName;
  final double expensivePrice;
  final String expensiveImageUrl;
  final String alternativeName;
  final double alternativePrice;
  final String alternativeImageUrl;
  final String buyUrl;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final bool isAutomated;
  final String? fragranceNotes;
  final String? activeIngredients;
  final String? localLocationLabel;
  final String? localLocationUrl;

  String get uniqueKey => documentId?.trim().isNotEmpty == true
      ? documentId!
      : '$categoryId|$expensiveName|$alternativeName|$buyUrl';

  bool get hasBuyUrl => buyUrl.trim().isNotEmpty;

  bool get hasOriginalOfferTag => tags.any(
        (tag) =>
            normalizeArabic(tag) ==
            normalizeArabic(LeastPriceDataConfig.originalOnSaleTag),
      );

  double get savingsAmount => expensivePrice - alternativePrice;

  double get savingsRatio {
    if (expensivePrice <= 0) {
      return 0;
    }

    return ((expensivePrice - alternativePrice) / expensivePrice)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int get savingsPercent => (savingsRatio * 100).round();

  bool get isSuperSaving => savingsRatio >= 0.40;

  bool get hasDetailHighlights =>
      (fragranceNotes?.trim().isNotEmpty ?? false) ||
      (activeIngredients?.trim().isNotEmpty ?? false);

  bool get hasLocationLink => localLocationUrl?.trim().isNotEmpty ?? false;

  List<String> get searchTokens => [
        categoryLabel,
        expensiveName,
        alternativeName,
        if (fragranceNotes != null) fragranceNotes!,
        if (activeIngredients != null) activeIngredients!,
        if (localLocationLabel != null) localLocationLabel!,
        ...tags,
      ];

  ProductComparison copyWith({
    String? documentId,
    String? categoryId,
    String? categoryLabel,
    String? expensiveName,
    double? expensivePrice,
    String? expensiveImageUrl,
    String? alternativeName,
    double? alternativePrice,
    String? alternativeImageUrl,
    String? buyUrl,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    bool? isAutomated,
    String? fragranceNotes,
    String? activeIngredients,
    String? localLocationLabel,
    String? localLocationUrl,
  }) {
    return ProductComparison(
      documentId: documentId ?? this.documentId,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      expensiveName: expensiveName ?? this.expensiveName,
      expensivePrice: expensivePrice ?? this.expensivePrice,
      expensiveImageUrl: expensiveImageUrl ?? this.expensiveImageUrl,
      alternativeName: alternativeName ?? this.alternativeName,
      alternativePrice: alternativePrice ?? this.alternativePrice,
      alternativeImageUrl: alternativeImageUrl ?? this.alternativeImageUrl,
      buyUrl: buyUrl ?? this.buyUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      isAutomated: isAutomated ?? this.isAutomated,
      fragranceNotes: fragranceNotes ?? this.fragranceNotes,
      activeIngredients: activeIngredients ?? this.activeIngredients,
      localLocationLabel: localLocationLabel ?? this.localLocationLabel,
      localLocationUrl: localLocationUrl ?? this.localLocationUrl,
    );
  }

  ProductComparison withUserRating(double userRating) {
    final totalReviews = reviewCount + 1;
    final newAverage = reviewCount <= 0
        ? userRating
        : ((rating * reviewCount) + userRating) / totalReviews;

    return copyWith(
      rating: newAverage.clamp(0.0, 5.0).toDouble(),
      reviewCount: totalReviews,
    );
  }

  factory ProductComparison.fromJson(Map<String, dynamic> json) {
    final expensive = asMap(json['expensive']);
    final alternative = asMap(json['alternative']);

    final categoryLabel =
        stringValue(json['categoryLabel'] ?? json['category']) ??
            tr('أخرى', 'Other');
    final expensiveName =
        stringValue(json['expensiveName'] ?? expensive['name']) ??
            tr('منتج مرتفع السعر', 'Higher-priced product');
    final alternativeName =
        stringValue(json['alternativeName'] ?? alternative['name']) ??
            tr('الخيار الاقتصادي', 'Best-value option');
    final normalizedTags = stringListValue(json['tags']);

    return ProductComparison(
      documentId: stringValue(json['documentId'] ?? json['id']),
      categoryId: stringValue(json['categoryId'])?.trim().isNotEmpty == true
          ? stringValue(json['categoryId'])!.trim()
          : ProductCategoryCatalog.inferId(categoryLabel),
      categoryLabel: categoryLabel,
      expensiveName: expensiveName,
      expensivePrice: doubleValue(json['expensivePrice'] ?? expensive['price']),
      expensiveImageUrl: normalizedImageUrl(
        stringValue(json['expensiveImageUrl'] ?? expensive['imageUrl']) ?? '',
        fallbackLabel: expensiveName,
      ),
      alternativeName: alternativeName,
      alternativePrice:
          doubleValue(json['alternativePrice'] ?? alternative['price']),
      alternativeImageUrl: normalizedImageUrl(
        stringValue(json['alternativeImageUrl'] ?? alternative['imageUrl']) ??
            '',
        fallbackLabel: alternativeName,
      ),
      buyUrl: AffiliateLinkService.attachAffiliateTag(
        stringValue(json['buyUrl']) ?? '',
      ),
      rating: doubleValue(json['rating']),
      reviewCount: intValue(json['reviewCount']),
      isAutomated: boolValue(json['is_automated'], defaultValue: true),
      tags: normalizedTags.isNotEmpty
          ? normalizedTags
          : [
              categoryLabel,
              expensiveName,
              alternativeName,
            ],
      fragranceNotes: stringValue(json['fragranceNotes']),
      activeIngredients: stringValue(json['activeIngredients']),
      localLocationLabel: stringValue(json['localLocationLabel']),
      localLocationUrl: stringValue(json['localLocationUrl']),
    );
  }

  factory ProductComparison.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ProductComparison.fromJson({
      ...?document.data(),
      'documentId': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'expensiveName': expensiveName,
      'expensivePrice': expensivePrice,
      'alternativeName': alternativeName,
      'alternativePrice': alternativePrice,
      'category': categoryLabel,
      'is_automated': isAutomated,
      if (buyUrl.trim().isNotEmpty)
        'buyUrl': AffiliateLinkService.attachAffiliateTag(buyUrl),
      'rating': rating,
      if (reviewCount > 0) 'reviewCount': reviewCount,
      if (tags.isNotEmpty) 'tags': tags,
      if (categoryId.trim().isNotEmpty) 'categoryId': categoryId,
      if (expensiveImageUrl.trim().isNotEmpty)
        'expensiveImageUrl': expensiveImageUrl,
      if (alternativeImageUrl.trim().isNotEmpty)
        'alternativeImageUrl': alternativeImageUrl,
      if (fragranceNotes != null && fragranceNotes!.trim().isNotEmpty)
        'fragranceNotes': fragranceNotes,
      if (activeIngredients != null && activeIngredients!.trim().isNotEmpty)
        'activeIngredients': activeIngredients,
      if (localLocationLabel != null && localLocationLabel!.trim().isNotEmpty)
        'localLocationLabel': localLocationLabel,
      if (localLocationUrl != null && localLocationUrl!.trim().isNotEmpty)
        'localLocationUrl': localLocationUrl,
    };
  }

  static final List<ProductComparison> mockData = [
    const ProductComparison(
      categoryId: 'coffee',
      categoryLabel: 'قهوة',
      expensiveName: 'نسكافيه جولد 200 جم',
      expensivePrice: 48.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'قهوة باجة السعودية 250 جم',
      alternativePrice: 24.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      buyUrl:
          'https://www.amazon.sa/s?k=%D9%82%D9%87%D9%88%D8%A9+%D8%A8%D8%A7%D8%AC%D8%A9',
      rating: 4.6,
      reviewCount: 184,
      tags: ['نسكافيه', 'باجة', 'قهوة فورية', 'مشروبات ساخنة'],
    ),
    const ProductComparison(
      categoryId: 'detergents',
      categoryLabel: 'منظفات',
      expensiveName: 'فيري سائل جلي 1 لتر',
      expensivePrice: 17.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1583947582886-f40ec95dd752?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'هوم كير سائل جلي اقتصادي 1 لتر',
      alternativePrice: 9.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=dishwashing%20liquid',
      rating: 4.2,
      reviewCount: 91,
      tags: ['تنظيف', 'جلي', 'مطبخ', 'أفضل قيمة'],
    ),
    const ProductComparison(
      categoryId: 'dairy',
      categoryLabel: 'ألبان',
      expensiveName: 'جبنة كرافت شرائح 400 جم',
      expensivePrice: 21.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'جبنة المراعي شرائح 400 جم',
      alternativePrice: 13.95,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1452195100486-9cc805987862?auto=format&fit=crop&w=900&q=80',
      buyUrl:
          'https://www.amazon.sa/s?k=%D8%AC%D8%A8%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D8%B1%D8%A7%D8%B9%D9%8A',
      rating: 4.4,
      reviewCount: 132,
      tags: ['جبنة', 'كرافت', 'المراعي', 'إفطار'],
    ),
    const ProductComparison(
      categoryId: 'canned',
      categoryLabel: 'معلبات',
      expensiveName: 'معجون طماطم هاينز 8 عبوات',
      expensivePrice: 18.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'معجون طماطم قودي 8 عبوات',
      alternativePrice: 10.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1576867757603-05b134ebc379?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=goody+tomato+paste',
      rating: 4.5,
      reviewCount: 88,
      tags: ['هاينز', 'قودي', 'طبخ', 'طماطم'],
    ),
    const ProductComparison(
      categoryId: 'tea',
      categoryLabel: 'شاي',
      expensiveName: 'شاي ليبتون 100 كيس',
      expensivePrice: 29.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'شاي ربيع 100 كيس',
      alternativePrice: 17.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=rabea%20tea',
      rating: 4.8,
      reviewCount: 240,
      tags: ['ليبتون', 'ربيع', 'شاي سعودي', 'مشروب ساخن'],
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'وجبة برجر مرجعية',
      expensivePrice: 26.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'برجر مدخن من مطعم برجر الشرقية - الخبر',
      alternativePrice: 18.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.hungerstation.com/sa-en',
      rating: 4.9,
      reviewCount: 278,
      tags: ['بيج ماك', 'برجر', 'الخبر', 'مطعم مميز', 'الشرقية'],
      localLocationLabel: 'الخبر - طريق الأمير تركي - مطعم برجر الشرقية',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+burger+restaurant',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'ساندوتش كرسبي مرجعي',
      expensivePrice: 24.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'كرسبي دجاج من مطعم أهل الخبر',
      alternativePrice: 16.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://jahez.net',
      rating: 4.7,
      reviewCount: 163,
      tags: ['كرسبي', 'دجاج', 'مطاعم الخبر', 'أفضل قيمة'],
      localLocationLabel: 'الخبر - حي الحزام الذهبي - مطعم أهل الخبر',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+crispy+chicken',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'آيس لاتيه مرجعي',
      expensivePrice: 21.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'آيس لاتيه من مقهى شرقي',
      alternativePrice: 13.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://mrsool.co',
      rating: 4.8,
      reviewCount: 121,
      tags: ['قهوة باردة', 'مقهى مميز', 'لاتيه', 'الشرقية'],
      localLocationLabel: 'الخبر - الكورنيش - مقهى شرقي',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+coffee+shop',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Dior Sauvage Eau de Parfum',
      expensivePrice: 520.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل سافاج من نخبة العود',
      alternativePrice: 189.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=sauvage+alternative',
      rating: 4.9,
      reviewCount: 312,
      tags: ['سافاج', 'نخبة العود', 'براند سعودي', 'بديل عطري'],
      fragranceNotes: 'برغموت، فلفل سيشوان، أمبروكسان، لمسة خشبية منعشة',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Baccarat Rouge 540',
      expensivePrice: 1210.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1523293182086-7651a899d37f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل بنفس الرائحة من العربية للعود',
      alternativePrice: 245.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=arabian+oud+perfume',
      rating: 4.8,
      reviewCount: 204,
      tags: ['بكارات', 'العربية للعود', 'عود', 'عنبر'],
      fragranceNotes: 'زعفران، ياسمين، عنبر، أخشاب دافئة وسكر محروق',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Chanel Coco Mademoiselle',
      expensivePrice: 615.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل فلورال من إبراهيم القرشي',
      alternativePrice: 210.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1588405748880-12d1d2a59df9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=ibrahim+alqurashi+perfume',
      rating: 4.7,
      reviewCount: 177,
      tags: ['شانيل', 'إبراهيم القرشي', 'فلورال', 'مسك'],
      fragranceNotes: 'برتقال، ورد تركي، باتشولي، مسك أبيض',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'The Ordinary Niacinamide 10% Serum',
      expensivePrice: 69.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'سيروم نياسيناميد من لاب سعودي',
      alternativePrice: 34.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1625772452859-1c03d5bf1137?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=niacinamide+serum',
      rating: 4.6,
      reviewCount: 143,
      tags: ['نياسيناميد', 'سيروم', 'بشرة', 'أفضل قيمة'],
      activeIngredients:
          'Niacinamide 10% + Zinc PCA لتنظيم الدهون وتقليل مظهر المسام',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'La Roche-Posay Vitamin C Serum',
      expensivePrice: 220.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1570194065650-d99fb4d8a5c8?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'سيروم فيتامين C من براند سعودي للعناية',
      alternativePrice: 96.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=vitamin+c+serum',
      rating: 4.5,
      reviewCount: 109,
      tags: ['فيتامين سي', 'سيروم', 'نضارة', 'مكونات فعالة'],
      activeIngredients:
          'Vitamin C + Hyaluronic Acid + Vitamin E لإشراقة وترطيب أعمق',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'Maybelline Fit Me Concealer',
      expensivePrice: 58.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1631730486782-d5a6bdf9a7ec?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'كونسيلر اقتصادي بتغطية خفيفة من بوتيك سعودي',
      alternativePrice: 27.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=concealer',
      rating: 4.4,
      reviewCount: 86,
      tags: ['كونسيلر', 'مكياج', 'تغطية', 'أفضل قيمة'],
      activeIngredients: 'Pigment blend + Glycerin لترطيب خفيف وثبات يومي',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'صيدلية',
      expensiveName: 'CeraVe Moisturizing Cream',
      expensivePrice: 89.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1556228578-dd6c36f7737d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'مرطب اقتصادي من الصيدلية',
      alternativePrice: 44.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.nahdionline.com',
      rating: 4.7,
      reviewCount: 221,
      tags: ['سيرافي', 'مرطب', 'نهدي', 'اقتصادي'],
      activeIngredients:
          'سيراميدات + هيالورونيك أسيد + بانثينول لدعم حاجز البشرة',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'صيدلية',
      expensiveName: 'Panadol Cold & Flu',
      expensivePrice: 24.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'خيار اقتصادي لنزلات البرد',
      alternativePrice: 14.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.al-dawaa.com',
      rating: 4.3,
      reviewCount: 75,
      tags: ['بانادول', 'برد', 'صيدلية', 'دواء'],
      activeIngredients: 'باراسيتامول + مزيل احتقان بتركيبة اقتصادية مشابهة',
    ),
  ];
}
