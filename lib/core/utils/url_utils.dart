import 'package:leastprice/core/utils/helpers.dart';

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
  if (normalizedHost.contains('jarir')) return 'jarir';
  if (normalizedHost.contains('extra')) return 'extra';
  if (normalizedHost.contains('danube')) return 'danube';
  if (normalizedHost.contains('bindawood')) return 'bindawood';
  if (normalizedHost.contains('manuel')) return 'manuel';
  if (normalizedHost.contains('ikea')) return 'ikea';
  if (normalizedHost.contains('saco')) return 'saco';
  if (normalizedHost.contains('niceone')) return 'niceone';
  if (normalizedHost.contains('goldenscent')) return 'goldenscent';
  if (normalizedHost.contains('sephora')) return 'sephora';
  if (normalizedHost.contains('abyat')) return 'abyat';
  if (normalizedHost.contains('homecentre')) return 'homecentre';
  if (normalizedHost.contains('homebox')) return 'homebox';
  if (normalizedHost.contains('blackbox')) return 'blackbox';
  return normalizedHost
      .replaceFirst('www.', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String? domainForStoreId(String storeId) {
  switch (storeId.trim().toLowerCase()) {
    case 'amazon':
      return 'amazon.sa';
    case 'noon':
      return 'noon.com';
    case 'hungerstation':
      return 'hungerstation.com';
    case 'panda':
      return 'panda.com.sa';
    case 'othaim':
      return 'othaimmarkets.com';
    case 'almazraa':
      return 'farm.com.sa';
    case 'lulu':
      return 'luluhypermarket.com';
    case 'carrefour':
      return 'carrefourksa.com';
    case 'tamimi':
      return 'tamimimarkets.com';
    case 'toyou':
      return 'toyou.io';
    case 'keeta':
      return 'keeta.com.sa';
    case 'nahdi':
      return 'nahdionline.com';
    case 'aldawaa':
      return 'al-dawaa.com';
    case 'jarir':
      return 'jarir.com';
    case 'extra':
      return 'extra.com';
    case 'danube':
      return 'danube.sa';
    case 'bindawood':
      return 'bindawood.com';
    case 'manuel':
      return 'manuelmarket.com';
    case 'ikea':
      return 'ikea.com.sa';
    case 'saco':
      return 'saco.sa';
    case 'niceone':
      return 'niceonesa.com';
    case 'goldenscent':
      return 'goldenscent.com';
    case 'sephora':
      return 'sephora.sa';
    case 'abyat':
      return 'abyat.com';
    case 'homecentre':
      return 'homecentre.com';
    case 'homebox':
      return 'homeboxstores.com';
    case 'blackbox':
      return 'blackbox.com.sa';
    default:
      return null;
  }
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
  if (normalizedName.contains('هنجرستيشن') ||
      normalizedName.contains('hungerstation')) {
    return 'hungerstation';
  }
  if (normalizedName.contains('بنده') || normalizedName.contains('panda')) {
    return 'panda';
  }
  if (normalizedName.contains('العثيم') || normalizedName.contains('othaim')) {
    return 'othaim';
  }
  if (normalizedName.contains('المزرعه') ||
      normalizedName.contains('almazraa') ||
      normalizedName.contains('farm')) {
    return 'almazraa';
  }
  if (normalizedName.contains('لولو') || normalizedName.contains('lulu')) {
    return 'lulu';
  }
  if (normalizedName.contains('كارفور') ||
      normalizedName.contains('carrefour')) {
    return 'carrefour';
  }
  if (normalizedName.contains('التميمي') || normalizedName.contains('tamimi')) {
    return 'tamimi';
  }
  if (normalizedName.contains('تويو') || normalizedName.contains('toyou')) {
    return 'toyou';
  }
  if (normalizedName.contains('كيتا') || normalizedName.contains('keeta')) {
    return 'keeta';
  }
  if (normalizedName.contains('النهدي') || normalizedName.contains('nahdi')) {
    return 'nahdi';
  }
  if (normalizedName.contains('الدواء') ||
      normalizedName.contains('dawaa') ||
      normalizedName.contains('aldawaa')) {
    return 'aldawaa';
  }
  if (normalizedName.contains('جرير') || normalizedName.contains('jarir')) {
    return 'jarir';
  }
  if (normalizedName.contains('اكسترا') ||
      normalizedName.contains('إكسترا') ||
      normalizedName.contains('extra')) {
    return 'extra';
  }
  if (normalizedName.contains('الدانوب') || normalizedName.contains('danube')) {
    return 'danube';
  }
  if (normalizedName.contains('بن داود') ||
      normalizedName.contains('bindawood')) {
    return 'bindawood';
  }
  if (normalizedName.contains('مانويل') || normalizedName.contains('manuel')) {
    return 'manuel';
  }
  if (normalizedName.contains('ايكيا') || normalizedName.contains('ikea')) {
    return 'ikea';
  }
  if (normalizedName.contains('ساكو') || normalizedName.contains('saco')) {
    return 'saco';
  }
  if (normalizedName.contains('نايس ون') ||
      normalizedName.contains('niceone')) {
    return 'niceone';
  }
  if (normalizedName.contains('قولدن سنت') ||
      normalizedName.contains('goldenscent')) {
    return 'goldenscent';
  }
  if (normalizedName.contains('سيفورا') || normalizedName.contains('sephora')) {
    return 'sephora';
  }
  if (normalizedName.contains('ابيات') || normalizedName.contains('abyat')) {
    return 'abyat';
  }
  if (normalizedName.contains('هوم سنتر') ||
      normalizedName.contains('homecentre')) {
    return 'homecentre';
  }
  if (normalizedName.contains('هوم بوكس') ||
      normalizedName.contains('homebox')) {
    return 'homebox';
  }
  if (normalizedName.contains('الصندوق الاسود') ||
      normalizedName.contains('blackbox')) {
    return 'blackbox';
  }

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
  if (normalized.contains('jarir') ||
      normalized.contains('extra') ||
      normalized.contains('جرير') ||
      normalized.contains('اكسترا') ||
      normalized.contains('إكسترا')) {
    return 'electronics';
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

String normalizeStoreIdToken(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
}

String normalizedImageUrl(
  String? rawUrl, {
  String fallbackLabel = 'LeastPrice',
}) {
  final value = (rawUrl ?? '').trim();

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
