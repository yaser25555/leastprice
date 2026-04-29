
import 'package:leastprice/core/config/least_price_data_config.dart';

class AffiliateLinkService {
  const AffiliateLinkService._();

  static final RegExp _phoneLikePattern = RegExp(r'^\+?[0-9\s\-\(\)]{8,}$');
  static const Set<String> supportedHosts = {
    'amazon.sa',
    'www.amazon.sa',
    'noon.com',
    'www.noon.com',
    'nahdionline.com',
    'www.nahdionline.com',
    'al-dawaa.com',
    'www.al-dawaa.com',
    'hungerstation.com',
    'www.hungerstation.com',
    'jahez.net',
    'www.jahez.net',
    'mrsool.co',
    'www.mrsool.co',
  };

  static bool isWhatsAppUri(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'wa.me' ||
        host == 'www.wa.me' ||
        host == 'api.whatsapp.com' ||
        host == 'whatsapp.com' ||
        host == 'www.whatsapp.com';
  }

  static bool looksLikeWhatsAppContact(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      return isWhatsAppUri(uri);
    }

    return _phoneLikePattern.hasMatch(trimmed);
  }

  static String normalizeContactLink(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      return trimmed;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 8) {
      return 'https://wa.me/$digitsOnly';
    }

    return trimmed;
  }

  static String attachAffiliateTag(String url) {
    final normalized = normalizeContactLink(url);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return normalized;
    }

    if (isWhatsAppUri(uri)) {
      return normalized;
    }

    final parameters = Map<String, String>.from(uri.queryParameters);
    parameters['tag'] = LeastPriceDataConfig.affiliateTag;

    return uri.replace(queryParameters: parameters).toString();
  }

  static bool isSupportedStore(Uri uri) {
    return supportedHosts.contains(uri.host.toLowerCase());
  }

  static String prepareForOpen(String rawUrl) {
    return attachAffiliateTag(rawUrl);
  }
}
