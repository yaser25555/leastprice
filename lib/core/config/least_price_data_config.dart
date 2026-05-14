import 'package:leastprice/core/config/enums.dart';

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
  static const String hybridSearchBaseUrlOverride = String.fromEnvironment(
    'HYBRID_SEARCH_BASE_URL',
    defaultValue:
        'https://leastprice-hybrid-search.leastprice-yaser.workers.dev',
  );
  static const String usersCollectionName = 'users';
  static const String popularProductsCollectionName = 'popular_products';
  static const String searchRequestsCollectionName = 'search_requests';
  static const String favoritesCollectionName = 'favorites';
  static const String priceHistoryCollectionName = 'price_history';
  static const String priceAlertsCollectionName = 'price_alerts';
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
  static const String noonReferralLink =
      'https://s.noon.com/HOTtsN31XfI';
  static const int comparisonSearchCacheHours = 24;

  /// DCMnetwork tracking links map
  static const Map<String, String> affiliateStoreLinks = {
    'yslbeauty.sa': 'https://go.urtrackinglink.com/SH9H2',
    'www.yslbeauty.sa': 'https://go.urtrackinglink.com/SH9H2',
    'sssports.com': 'https://go.urtrackinglink.com/SH9HA',
    'en-ae.sssports.com': 'https://go.urtrackinglink.com/SH9HA',
    'nike.sa': 'https://go.urtrackinglink.com/SH9H4',
    'www.nike.sa': 'https://go.urtrackinglink.com/SH9H4',
    'hm.com': 'https://go.urtrackinglink.com/SH9H5',
    'ae.hm.com': 'https://go.urtrackinglink.com/SH9H5',
    'ntshop.sa': 'https://go.urtrackinglink.com/SH9HF',
    'www.ntshop.sa': 'https://go.urtrackinglink.com/SH9HF',
    'hudabeauty.com': 'https://go.urtrackinglink.com/SH9H6',
    'www.hudabeauty.com': 'https://go.urtrackinglink.com/SH9H6',
    'underarmour.ae': 'https://go.urtrackinglink.com/SH9H7',
    'www.underarmour.ae': 'https://go.urtrackinglink.com/SH9H7',
    'mamasandpapas.ae': 'https://go.urtrackinglink.com/SH9H8',
    'www.mamasandpapas.ae': 'https://go.urtrackinglink.com/SH9H8',
    'bloomingdales.ae': 'https://go.urtrackinglink.com/SH9H9',
    'www.bloomingdales.ae': 'https://go.urtrackinglink.com/SH9H9',
    'puma.com': 'https://go.urtrackinglink.com/SH9HB',
    'sa.puma.com': 'https://go.urtrackinglink.com/SH9HB',
  };

  static const String originalOnSaleTag = 'المنتج الأصلي عليه عرض حالياً';
  static const SearchProviderType searchProviderType =
      SearchProviderType.serper;

  static const String tavilyApiKey =
      String.fromEnvironment('TAVILY_API_KEY', defaultValue: '');
  static const bool enableAutomaticPriceRefresh = true;

  static const String oneSignalAppId = '715316fc-13d0-4fee-b0f8-860b4d38dee6';
}
