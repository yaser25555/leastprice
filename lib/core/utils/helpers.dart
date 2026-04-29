import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';

// -- Language System ----------------------------------------------------------
final ValueNotifier<String> appLang = ValueNotifier<String>('ar');

bool get isAr => appLang.value == 'ar';

String tr(String ar, String en) => isAr ? ar : en;

String requiredFieldMessage(String arLabel, String enLabel) =>
    tr('$arLabel مطلوب.', '$enLabel is required.');

String validValueMessage(String arLabel, String enLabel) => tr(
      'أدخل قيمة صحيحة لـ $arLabel.',
      'Enter a valid value for $enLabel.',
    );

String validUrlMessage(String arLabel, String enLabel) => tr(
      'أدخل $arLabel صالحاً يبدأ بـ http أو https.',
      'Enter a valid $enLabel that starts with http or https.',
    );

String localizedCategoryLabelForId(
  String categoryId, {
  String? fallbackLabel,
}) {
  switch (categoryId.trim()) {
    case ProductCategoryCatalog.allId:
      return tr('الكل', 'All');
    case 'coffee':
      return tr('قهوة', 'Coffee');
    case 'roasters':
      return tr('محامص', 'Roasters');
    case 'restaurants':
      return tr('مطاعم', 'Restaurants');
    case 'perfumes':
      return tr('عطور', 'Perfumes');
    case 'cosmetics':
      return tr('تجميل', 'Beauty');
    case 'pharmacy':
      return tr('صيدلية', 'Pharmacy');
    case 'detergents':
      return tr('منظفات', 'Detergents');
    case 'dairy':
      return tr('ألبان', 'Dairy');
    case 'canned':
      return tr('معلبات', 'Canned');
    case 'tea':
      return tr('شاي', 'Tea');
    case 'juice':
      return tr('عصير', 'Juice');
    default:
      return localizedKnownLabel(fallbackLabel ?? categoryId);
  }
}

String localizedKnownLabel(String value) {
  final normalized = normalizeArabic(value);

  if (normalized == 'الكل') return tr('الكل', 'All');
  if (normalized == 'قهوه') return tr('قهوة', 'Coffee');
  if (normalized == 'محامص') return tr('محامص', 'Roasters');
  if (normalized == 'مطاعم') return tr('مطاعم', 'Restaurants');
  if (normalized == 'عطور') return tr('عطور', 'Perfumes');
  if (normalized == 'تجميل') return tr('تجميل', 'Beauty');
  if (normalized == 'صيدليه') return tr('صيدلية', 'Pharmacy');
  if (normalized == 'منظفات') return tr('منظفات', 'Detergents');
  if (normalized == 'البان') return tr('ألبان', 'Dairy');
  if (normalized == 'معلبات') return tr('معلبات', 'Canned');
  if (normalized == 'شاي') return tr('شاي', 'Tea');
  if (normalized == 'عصير') return tr('عصير', 'Juice');
  if (normalized == normalizeArabic(LeastPriceDataConfig.originalOnSaleTag)) {
    return tr(
      'المنتج الأصلي عليه عرض حالياً',
      'Original product is on sale now',
    );
  }
  if (normalized == normalizeArabic('توفير خارق')) {
    return tr('توفير خارق', 'Super saving');
  }

  return value;
}

enum HomeCatalogSection {
  offers,
  comparisons,
}

class MarketplaceSearchCity {
  const MarketplaceSearchCity({
    required this.id,
    required this.arLabel,
    required this.enLabel,
    required this.serpApiLocation,
  });

  final String id;
  final String arLabel;
  final String enLabel;
  final String serpApiLocation;

  String get label => tr(arLabel, enLabel);
}

const List<MarketplaceSearchCity> marketplaceSearchCities = [
  MarketplaceSearchCity(
    id: 'saudi_arabia',
    arLabel: 'كل السعودية',
    enLabel: 'All Saudi Arabia',
    serpApiLocation: 'Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'riyadh',
    arLabel: 'الرياض',
    enLabel: 'Riyadh',
    serpApiLocation: 'Riyadh Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'jeddah',
    arLabel: 'جدة',
    enLabel: 'Jeddah',
    serpApiLocation: 'Jeddah Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'dammam',
    arLabel: 'الدمام',
    enLabel: 'Dammam',
    serpApiLocation: 'Dammam Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'khobar',
    arLabel: 'الخبر',
    enLabel: 'Khobar',
    serpApiLocation: 'Khobar Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'makkah',
    arLabel: 'مكة',
    enLabel: 'Makkah',
    serpApiLocation: 'Makkah Saudi Arabia',
  ),
  MarketplaceSearchCity(
    id: 'madinah',
    arLabel: 'المدينة',
    enLabel: 'Madinah',
    serpApiLocation: 'Madinah Saudi Arabia',
  ),
];

MarketplaceSearchCity marketplaceSearchCityById(String? id) {
  final normalizedId = (id ?? '').trim().toLowerCase();
  return marketplaceSearchCities.firstWhere(
    (city) => city.id == normalizedId,
    orElse: () => marketplaceSearchCities.first,
  );
}

// ----------------------------------------------------------------------------

// ─── لوحة البنرات البسيطة ────────────────────────────────────────────────────

// ─── لوحة المنتجات البسيطة ───────────────────────────────────────────────────

String? formatSaudiPhoneNumber(String rawNumber) {
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+9665') && digits.length == 13) {
    return digits;
  }
  if (digits.startsWith('9665') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('05') && digits.length == 10) {
    return '+966${digits.substring(1)}';
  }
  if (digits.startsWith('5') && digits.length == 9) {
    return '+966$digits';
  }
  return null;
}

String? normalizeEmailAddress(String rawEmail) {
  final value = rawEmail.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }

  const pattern = r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
  return RegExp(pattern, caseSensitive: false).hasMatch(value) ? value : null;
}

String normalizedImageUrl(
  String? rawUrl, {
  String fallbackLabel = 'LeastPrice',
}) {
  final value = (rawUrl ?? '').trim();

  // رابط فارغ أو localhost أو غير صالح → placeholder آمنة
  final isLocalhost = value.contains('localhost') ||
      value.contains('127.0.0.1') ||
      value.contains('0.0.0.0');
  final isValidScheme =
      value.startsWith('http://') || value.startsWith('https://');

  if (value.isEmpty || isLocalhost || !isValidScheme) {
    final encoded = Uri.encodeComponent(
        fallbackLabel.isNotEmpty ? fallbackLabel : 'LeastPrice');
    return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
  }

  const brokenTokens = <String>[
    'photo-1570194065650-d99fb4d8a5c8',
    'photo-1556228578-dd6c36f7737d',
    'photo-1588405748880-12d1d2a59df9',
  ];

  for (final token in brokenTokens) {
    if (value.contains(token)) {
      final encoded = Uri.encodeComponent(fallbackLabel);
      return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
    }
  }

  return value;
}

String arabicAuthMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return tr(
        'صيغة البريد الإلكتروني غير صحيحة.',
        'The email format is invalid.',
      );
    case 'email-already-in-use':
      return tr(
        'هذا البريد مستخدم بالفعل. جرّب تسجيل الدخول بدلاً من إنشاء حساب جديد.',
        'This email is already in use. Try signing in instead of creating a new account.',
      );
    case 'weak-password':
      return tr(
        'كلمة المرور ضعيفة جداً. اختر كلمة مرور أقوى.',
        'The password is too weak. Choose a stronger password.',
      );
    case 'user-not-found':
    case 'invalid-credential':
      return tr(
        'بيانات الدخول غير صحيحة. تأكد من البريد وكلمة المرور.',
        'Your sign-in details are incorrect. Check your email and password.',
      );
    case 'wrong-password':
      return tr('كلمة المرور غير صحيحة.', 'Incorrect password.');
    case 'operation-not-allowed':
      return tr(
        'تسجيل الدخول بالبريد الإلكتروني وكلمة المرور غير مفعّل في Firebase Authentication بعد. فعّل مزود Email/Password من لوحة Firebase ثم أعد المحاولة.',
        'Email/password sign-in is not enabled in Firebase Authentication yet. Enable the Email/Password provider in Firebase, then try again.',
      );
    case 'internal-error':
      final details = (error.message ?? '').toUpperCase();
      if (details.contains('CONFIGURATION_NOT_FOUND')) {
        return tr(
          'إعدادات Firebase Authentication غير مكتملة لهذا النوع من تسجيل الدخول. فعّل Email/Password من Firebase Console ثم أعد المحاولة.',
          'Firebase Authentication is not fully configured for this sign-in method. Enable Email/Password in Firebase Console and try again.',
        );
      }
      return tr(
        'حدث خطأ داخلي في Firebase Authentication. تحقق من إعدادات تسجيل الدخول ثم أعد المحاولة.',
        'A Firebase Authentication internal error occurred. Check your sign-in settings and try again.',
      );
    case 'too-many-requests':
      return tr(
        'تم إجراء محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.',
        'Too many attempts were made. Please wait a moment and try again.',
      );
    case 'network-request-failed':
      return tr(
        'تعذر الاتصال بـ Firebase حالياً. تحقق من الإنترنت ثم أعد المحاولة.',
        'Unable to reach Firebase right now. Check your internet connection and try again.',
      );
    default:
      return error.message ??
          tr('حدث خطأ في المصادقة. حاول مرة أخرى.',
              'Authentication failed. Try again.');
  }
}

DateTime? dateTimeValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String formatHealthTimestamp(DateTime? value) {
  if (value == null) {
    return tr('بانتظار أول تحديث', 'Waiting for first update');
  }

  final local = value.toLocal();
  final twoDigitsHour = local.hour.toString().padLeft(2, '0');
  final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
  final twoDigitsDay = local.day.toString().padLeft(2, '0');
  final twoDigitsMonth = local.month.toString().padLeft(2, '0');
  return '$twoDigitsHour:$twoDigitsMinute - $twoDigitsDay/$twoDigitsMonth';
}

String formatDealExpiryLabel(DateTime? value) {
  if (value == null) {
    return tr('بدون تاريخ', 'No date');
  }

  final local = value.toLocal();
  final twoDigitsDay = local.day.toString().padLeft(2, '0');
  final twoDigitsMonth = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$twoDigitsDay/$twoDigitsMonth/$year';
}

// ignore: unused_element

// ignore: unused_element

enum ProductDataSource {
  remote,
  asset,
  mock,
}

extension ProductDataSourceLabel on ProductDataSource {
  String get label {
    switch (this) {
      case ProductDataSource.remote:
        return tr('رابط خارجي', 'Remote feed');
      case ProductDataSource.asset:
        return tr('ملف JSON', 'JSON file');
      case ProductDataSource.mock:
        return tr('بيانات تجريبية', 'Mock data');
    }
  }
}

enum SearchProviderType {
  serper,
  tavily,
}

enum ComparisonSearchSourceType {
  serpApi,
  scraper,
}

extension ComparisonSearchSourceTypeLabel on ComparisonSearchSourceType {
  String get label {
    switch (this) {
      case ComparisonSearchSourceType.serpApi:
        return tr('LeastPrice', 'LeastPrice');
      case ComparisonSearchSourceType.scraper:
        return tr('مباشر من المتجر', 'Direct store scrape');
    }
  }
}

enum ComparisonSearchChannelType {
  marketplace,
  hypermarket,
  delivery,
  pharmacy,
  other,
}

extension ComparisonSearchChannelTypeLabel on ComparisonSearchChannelType {
  String get label {
    switch (this) {
      case ComparisonSearchChannelType.marketplace:
        return tr('منصة كبرى', 'Marketplace');
      case ComparisonSearchChannelType.hypermarket:
        return tr('هايبر ماركت', 'Hypermarket');
      case ComparisonSearchChannelType.delivery:
        return tr('تطبيق توصيل', 'Delivery app');
      case ComparisonSearchChannelType.pharmacy:
        return tr('صيدلية', 'Pharmacy');
      case ComparisonSearchChannelType.other:
        return tr('متجر محلي', 'Local store');
    }
  }
}

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const {};
}

String? stringValue(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool sameStringLists(List<String> first, List<String> second) {
  if (identical(first, second)) {
    return true;
  }

  if (first.length != second.length) {
    return false;
  }

  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }

  return true;
}

double doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final normalized = value
        .trim()
        .replaceAll('٫', '.')
        .replaceAll('٬', '')
        .replaceAll(',', '');
    return double.tryParse(normalized) ??
        extractMarketplacePrice(normalized) ??
        0;
  }

  return 0;
}

int intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

bool boolValue(Object? value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return defaultValue;
}

List<String> stringListValue(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String formatPrice(double price) {
  return '${formatAmountValue(price)} ${tr('ر.س', 'SAR')}';
}

String formatAmountValue(double amount) {
  final hasFraction = amount != amount.roundToDouble();
  return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

double? extractMarketplacePrice(String text) {
  final normalized = text
      .replaceAll('٫', '.')
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .replaceAll(
          RegExp(r'(?:SAR|ر\.?\s?س|ريال(?:\s+سعودي)?)', caseSensitive: false),
          ' ')
      .trim();
  if (normalized.isEmpty) {
    return null;
  }

  final patterns = <RegExp>[
    RegExp(
      r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
      caseSensitive: false,
    ),
    RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
  }

  return null;
}

ComparisonSearchSourceType comparisonSearchSourceTypeFromString(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  if (normalized.contains('scrap') || normalized.contains('live')) {
    return ComparisonSearchSourceType.scraper;
  }
  return ComparisonSearchSourceType.serpApi;
}

ComparisonSearchChannelType comparisonSearchChannelTypeFromString(
    String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'marketplace':
      return ComparisonSearchChannelType.marketplace;
    case 'hypermarket':
      return ComparisonSearchChannelType.hypermarket;
    case 'delivery':
      return ComparisonSearchChannelType.delivery;
    case 'pharmacy':
      return ComparisonSearchChannelType.pharmacy;
    default:
      return ComparisonSearchChannelType.other;
  }
}

String normalizeStoreIdToken(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
}

String? hostFromUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasAuthority) {
    return parsed.host.toLowerCase();
  }
  final fallback = Uri.tryParse('https://$url');
  if (fallback != null && fallback.hasAuthority) {
    return fallback.host.toLowerCase();
  }
  return null;
}

String? storeIdForHost(String? host) {
  final normalizedHost = (host ?? '').toLowerCase();
  if (normalizedHost.isEmpty) {
    return null;
  }
  if (normalizedHost.contains('amazon')) return 'amazon';
  if (normalizedHost.contains('noon')) return 'noon';
  if (normalizedHost.contains('namshi')) return 'namshi';
  if (normalizedHost.contains('hungerstation')) return 'hungerstation';
  if (normalizedHost.contains('panda')) return 'panda';
  if (normalizedHost.contains('othaim')) return 'othaim';
  if (normalizedHost.contains('farm')) return 'almazraa';
  if (normalizedHost.contains('lulu')) return 'lulu';
  if (normalizedHost.contains('carrefour')) return 'carrefour';
  if (normalizedHost.contains('tamimi')) return 'tamimi';
  if (normalizedHost.contains('toyou')) return 'toyou';
  if (normalizedHost.contains('keeta')) return 'keeta';
  if (normalizedHost.contains('nahdi')) return 'nahdi';
  if (normalizedHost.contains('dawaa')) return 'aldawaa';
  return normalizedHost
      .replaceFirst('www.', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String? inferStoreIdFromUrl(String url, {String? fallbackName}) {
  final hostStoreId = storeIdForHost(hostFromUrl(url));
  if (hostStoreId != null && hostStoreId.isNotEmpty) {
    return hostStoreId;
  }

  final normalizedName = normalizeArabic(fallbackName ?? '');
  if (normalizedName.contains('امازون') || normalizedName.contains('amazon')) {
    return 'amazon';
  }
  if (normalizedName.contains('نون') || normalizedName.contains('noon')) {
    return 'noon';
  }
  if (normalizedName.contains('نمشي') || normalizedName.contains('namshi')) {
    return 'namshi';
  }
  if (normalizedName.contains('هنجرستيشن')) return 'hungerstation';
  if (normalizedName.contains('بنده')) return 'panda';
  if (normalizedName.contains('العثيم')) return 'othaim';
  if (normalizedName.contains('المزرعه')) return 'almazraa';
  if (normalizedName.contains('لولو')) return 'lulu';
  if (normalizedName.contains('كارفور')) return 'carrefour';
  if (normalizedName.contains('التميمي')) return 'tamimi';
  if (normalizedName.contains('تويو')) return 'toyou';
  if (normalizedName.contains('كيتا')) return 'keeta';
  if (normalizedName.contains('النهدي')) return 'nahdi';
  if (normalizedName.contains('الدواء')) return 'aldawaa';

  final fallbackToken = normalizeStoreIdToken(fallbackName ?? '');
  return fallbackToken.isEmpty ? null : fallbackToken;
}

String inferComparisonChannelType(
  String storeId,
  String productUrl,
  String storeName,
) {
  final normalized =
      normalizeArabic('$storeId ${hostFromUrl(productUrl) ?? ''} $storeName');
  if (normalized.contains('nahdi') ||
      normalized.contains('dawaa') ||
      normalized.contains('نهدي') ||
      normalized.contains('دواء')) {
    return 'pharmacy';
  }
  if (normalized.contains('hungerstation') ||
      normalized.contains('toyou') ||
      normalized.contains('keeta') ||
      normalized.contains('هنجرستيشن') ||
      normalized.contains('تويو') ||
      normalized.contains('كيتا')) {
    return 'delivery';
  }
  if (normalized.contains('amazon') ||
      normalized.contains('noon') ||
      normalized.contains('namshi') ||
      normalized.contains('امازون') ||
      normalized.contains('نون') ||
      normalized.contains('نمشي')) {
    return 'marketplace';
  }
  if (normalized.contains('panda') ||
      normalized.contains('othaim') ||
      normalized.contains('lulu') ||
      normalized.contains('carrefour') ||
      normalized.contains('tamimi') ||
      normalized.contains('farm') ||
      normalized.contains('بنده') ||
      normalized.contains('العثيم') ||
      normalized.contains('لولو') ||
      normalized.contains('كارفور') ||
      normalized.contains('التميمي') ||
      normalized.contains('المزرعه')) {
    return 'hypermarket';
  }
  return 'other';
}

String resolveStoreLogoUrl({
  required String storeId,
  required String productUrl,
  String? fallbackName,
}) {
  const knownHosts = <String, String>{
    'amazon': 'amazon.sa',
    'noon': 'noon.com',
    'namshi': 'namshi.com',
    'hungerstation': 'hungerstation.com',
    'panda': 'panda.sa',
    'othaim': 'othaimmarkets.com',
    'almazraa': 'farm.com.sa',
    'lulu': 'luluhypermarket.com',
    'carrefour': 'carrefourksa.com',
    'tamimi': 'tamimimarkets.com',
    'toyou': 'toyou.io',
    'keeta': 'keeta.com',
    'nahdi': 'nahdionline.com',
    'aldawaa': 'al-dawaa.com',
  };

  final host = hostFromUrl(productUrl) ??
      knownHosts[storeId] ??
      knownHosts[normalizeStoreIdToken(storeId)] ??
      knownHosts[normalizeStoreIdToken(
        inferStoreIdFromUrl('', fallbackName: fallbackName) ?? '',
      )];
  if (host == null || host.isEmpty) {
    return '';
  }

  return Uri.https('www.google.com', '/s2/favicons', {
    'domain_url': 'https://$host',
    'sz': '128',
  }).toString();
}

String normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool isAdminDashboardRequest([Uri? uri]) {
  final target = uri ?? Uri.base;
  final path = target.path;
  final fragment = target.fragment;

  return isAdminPathToken(path) ||
      isAdminPathToken(fragment) ||
      target.queryParameters['admin'] == '1' ||
      target.queryParameters['view']?.toLowerCase() == 'admin';
}

bool isAdminPathToken(String? rawValue) {
  final value = (rawValue ?? '').trim().toLowerCase().replaceAll('\\', '/');
  if (value.isEmpty) {
    return false;
  }

  return value == 'admin' ||
      value == '/admin' ||
      value.endsWith('/admin') ||
      value.startsWith('/admin?');
}

bool isAllowedAdminEmail(String? email) {
  return (email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();
}
