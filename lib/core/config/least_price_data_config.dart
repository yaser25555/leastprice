import 'package:leastprice/core/utils/helpers.dart';

/// App-wide configuration constants.
///
/// **Sensitive values** (API keys, passwords) are injected at build time via
/// `--dart-define`. Example build command:
///
/// ```bash
/// flutter run \
///   --dart-define=SERPAPI_KEY=your_key \
///   --dart-define=SERPER_API_KEY=your_key \
///   --dart-define=ADMIN_PASSWORD=your_password
/// ```
class LeastPriceDataConfig {
  const LeastPriceDataConfig._();

  static const String productsCollectionName = 'products';
  static const String adBannersCollectionName = 'ad_banners';
  static const String exclusiveDealsCollectionName = 'exclusive_deals';
  static const String couponsCollectionName = 'coupons';
  static const String comparisonSearchCacheCollectionName =
      'comparison_search_cache';
  static const String adminUploadsPath = 'admin_uploads';
  static const String functionsRegion = 'us-central1';
  static const String hybridSearchFunctionName = 'hybridMarketplaceSearch';
  static const String usersCollectionName = 'users';
  static const String popularProductsCollectionName = 'popular_products';
  static const String searchRequestsCollectionName = 'search_requests';
  static const String systemHealthCollectionName = 'system_health';
  static const String systemHealthDocumentId = 'daily_price_bot';
  static const String remoteJsonUrl =
      'https://leastprice-yaser.web.app/assets/assets/data/products.json';
  static const String assetJsonPath = 'assets/data/products.json';
  static const String appShareUrl = 'https://leastprice-yaser.web.app/';
  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'yaser.haroon79@gmail.com',
  );
  static const String adminWhatsAppNumber = String.fromEnvironment(
    'ADMIN_WHATSAPP_NUMBER',
    defaultValue: '00966558570889',
  );
  static const String adminWhatsAppUrl = String.fromEnvironment(
    'ADMIN_WHATSAPP_URL',
    defaultValue: 'https://wa.me/966558570889',
  );

  /// Admin password — pass via `--dart-define=ADMIN_PASSWORD=...` at build time.
  static const String adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: '',
  );

  static const String affiliateTag = 'leastprice09-21';
  static const int comparisonSearchCacheHours = 24;

  /// DCMnetwork tracking links map
  static const Map<String, String> affiliateStoreLinks = {
    'noon.com': 'https://go.urtrackinglink.com/SH9H0',
    'www.noon.com': 'https://go.urtrackinglink.com/SH9H0',
    'yslbeauty.sa': 'https://go.urtrackinglink.com/SH9H2',
    'www.yslbeauty.sa': 'https://go.urtrackinglink.com/SH9H2',
    'sssports.com': 'https://go.urtrackinglink.com/SH9H3',
    'en-ae.sssports.com': 'https://go.urtrackinglink.com/SH9H3',
    'nike.sa': 'https://go.urtrackinglink.com/SH9H4',
    'www.nike.sa': 'https://go.urtrackinglink.com/SH9H4',
    'hm.com': 'https://go.urtrackinglink.com/SH9H5',
    'ae.hm.com': 'https://go.urtrackinglink.com/SH9H5',
    'ntshop.sa': 'https://go.urtrackinglink.com/SH9H5',
    'www.ntshop.sa': 'https://go.urtrackinglink.com/SH9H5',
    'hudabeauty.com': 'https://go.urtrackinglink.com/SH9H6',
    'www.hudabeauty.com': 'https://go.urtrackinglink.com/SH9H6',
  };

  /// SerpApi key — pass via `--dart-define=SERPAPI_KEY=...` at build time.
  static const String serpApiKey = String.fromEnvironment(
    'SERPAPI_KEY',
    defaultValue: '',
  );

  static const String originalOnSaleTag = 'المنتج الأصلي عليه عرض حالياً';
  static const SearchProviderType searchProviderType =
      SearchProviderType.serper;

  /// Serper API key — pass via `--dart-define=SERPER_API_KEY=...` at build time.
  static const String serperApiKey = String.fromEnvironment(
    'SERPER_API_KEY',
    defaultValue: '',
  );

  static const String tavilyApiKey =
      String.fromEnvironment('TAVILY_API_KEY', defaultValue: '');
  static const bool enableAutomaticPriceRefresh = true;
}
