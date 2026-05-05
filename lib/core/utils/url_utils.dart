import 'package:leastprice/core/utils/helpers.dart';

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

String? inferStoreIdFromUrl(String url, {String? fallbackName}) {
  final cleanUrl = url.trim().toLowerCase();
  
  if (cleanUrl.contains('amazon.sa') || cleanUrl.contains('amzn.to')) {
    return 'amazon';
  }
  if (cleanUrl.contains('noon.com')) {
    return 'noon';
  }
  if (cleanUrl.contains('jarir.com')) {
    return 'jarir';
  }
  if (cleanUrl.contains('extra.com')) {
    return 'extra';
  }
  if (cleanUrl.contains('nahdionline.com')) {
    return 'nahdi';
  }
  if (cleanUrl.contains('al-dawaa.com')) {
    return 'aldawaa';
  }
  if (cleanUrl.contains('panda-click.com') || cleanUrl.contains('panda.com')) {
    return 'panda';
  }
  if (cleanUrl.contains('othaimmarkets.com')) {
    return 'othaim';
  }
  if (cleanUrl.contains('carrefourksa.com')) {
    return 'carrefour';
  }
  if (cleanUrl.contains('luluhypermarket.com')) {
    return 'lulu';
  }
  if (cleanUrl.contains('niceonesa.com')) {
    return 'niceone';
  }
  if (cleanUrl.contains('sephora.sa')) {
    return 'sephora';
  }
  if (cleanUrl.contains('hungerstation.com')) {
    return 'hungerstation';
  }
  if (cleanUrl.contains('jahez.net')) {
    return 'jahez';
  }
  if (cleanUrl.contains('toyou.io')) {
    return 'toyou';
  }
  if (cleanUrl.contains('whites.net')) {
    return 'whites';
  }

  final name = (fallbackName ?? '').trim().toLowerCase();
  if (name.isEmpty) return null;

  if (name.contains('امازون') || name.contains('amazon')) return 'amazon';
  if (name.contains('نون') || name.contains('noon')) return 'noon';
  if (name.contains('جرير') || name.contains('jarir')) return 'jarir';
  if (name.contains('اكسترا') || name.contains('extra')) return 'extra';
  if (name.contains('النهدي') || name.contains('nahdi')) return 'nahdi';
  if (name.contains('الدواء') || name.contains('aldawaa')) return 'aldawaa';
  if (name.contains('بنده') || name.contains('panda')) return 'panda';
  if (name.contains('العثيم') || name.contains('othaim')) return 'othaim';
  if (name.contains('كارفور') || name.contains('carrefour')) return 'carrefour';
  if (name.contains('لولو') || name.contains('lulu')) return 'lulu';
  if (name.contains('نايس ون') || name.contains('niceone')) return 'niceone';
  if (name.contains('سيفورا') || name.contains('sephora')) return 'sephora';
  if (name.contains('هنقرستيشن') || name.contains('hungerstation')) return 'hungerstation';
  if (name.contains('جاهز') || name.contains('jahez')) return 'jahez';
  if (name.contains('تويو') || name.contains('toyou')) return 'toyou';
  if (name.contains('وايتس') || name.contains('whites')) return 'whites';

  return null;
}

String resolveStoreLogoUrl({
  required String storeId,
  required String productUrl,
  required String fallbackName,
}) {
  final finalStoreId =
      storeId == 'unknown' ? inferStoreIdFromUrl(productUrl, fallbackName: fallbackName) : storeId;

  if (finalStoreId != null && finalStoreId != 'unknown') {
    return 'assets/icons/brands/$finalStoreId.png';
  }

  return 'assets/icons/brands/default_store.png';
}
