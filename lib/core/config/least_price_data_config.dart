import 'package:leastprice/core/utils/helpers.dart';

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
  static const String adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: '123456',
  );
  static const String affiliateTag = 'leastprice09-21';
  static const int comparisonSearchCacheHours = 24;
  static const String serpApiKey = String.fromEnvironment(
    'SERPAPI_KEY',
    defaultValue:
        '8f5e0a4c11cb0e6972f549ee390b083531ca2545ef1c02593c20efae8e917861',
  );
  static const String originalOnSaleTag = 'المنتج الأصلي عليه عرض حالياً';
  static const SearchProviderType searchProviderType =
      SearchProviderType.serper;
  static const String serperApiKey =
      String.fromEnvironment('SERPER_API_KEY', defaultValue: 'f7fa2546aac3050cc7972a4265217d42c3c38ff4c');
  static const String tavilyApiKey =
      String.fromEnvironment('TAVILY_API_KEY', defaultValue: '');
  static const bool enableAutomaticPriceRefresh = true;
}
