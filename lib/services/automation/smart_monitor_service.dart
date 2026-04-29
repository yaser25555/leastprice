import 'dart:async';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/search_result_item.dart';
import 'package:leastprice/services/automation/search_automation_client.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/data/models/catalog_refresh_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SmartMonitorService {
  const SmartMonitorService();

  Future<CatalogRefreshResult> refreshProducts(
    List<ProductComparison> products,
  ) async {
    if (!LeastPriceDataConfig.enableAutomaticPriceRefresh) {
      return CatalogRefreshResult(
        products: products,
        notice: tr(
          'التحديث التلقائي للأسعار معطل حالياً من الإعدادات.',
          'Automatic price refresh is currently disabled in settings.',
        ),
      );
    }

    final searchClient = SearchAutomationClient.fromConfig();
    if (searchClient == null) {
      return CatalogRefreshResult(
        products: products,
        notice: tr(
          'تم تفعيل منطق التحديث الذكي للأسعار، لكنه يحتاج مفتاح API صالحاً لـ Serper أو Tavily.',
          'Smart price refresh is enabled, but it still needs a valid Serper or Tavily API key.',
        ),
      );
    }

    final refreshedProducts = await Future.wait(
      products.map((product) => _refreshSingleProduct(searchClient, product)),
    );

    final refreshedCount = refreshedProducts
        .asMap()
        .entries
        .where((entry) => entry.value != products[entry.key])
        .length;

    return CatalogRefreshResult(
      products: refreshedProducts,
      notice: refreshedCount > 0
          ? tr(
              'تم تحديث $refreshedCount منتجاً تلقائياً من نتائج البحث السعودية.',
              '$refreshedCount products were automatically updated from Saudi search results.',
            )
          : tr(
              'لم يتم العثور على أسعار أحدث من موصل البحث الحالي، فتم الإبقاء على البيانات الحالية.',
              'No newer prices were found from the current search connector, so the current data was kept.',
            ),
    );
  }

  Future<ProductComparison> _refreshSingleProduct(
    SearchAutomationClient searchClient,
    ProductComparison product,
  ) async {
    try {
      final expensiveCandidates = await searchClient.search(
        _buildExpensiveQuery(product),
      );
      final alternativeCandidates = await searchClient.search(
        _buildAlternativeQuery(product),
      );

      final expensiveMatch = _selectBestMatch(
        expensiveCandidates,
        preferredHosts: const ['amazon.sa', 'noon.com'],
      );
      final alternativeMatch = _selectBestMatch(
        alternativeCandidates,
        preferredHosts: const [
          'amazon.sa',
          'noon.com',
          'nahdionline.com',
          'al-dawaa.com',
          'hungerstation.com',
          'jahez.net',
          'mrsool.co',
        ],
        requirePreferredHost: true,
      );

      final expensivePrice = expensiveMatch == null
          ? product.expensivePrice
          : _extractPrice(expensiveMatch.title, expensiveMatch.snippet) ??
              product.expensivePrice;

      final alternativePrice = alternativeMatch == null
          ? product.alternativePrice
          : _extractPrice(alternativeMatch.title, alternativeMatch.snippet) ??
              product.alternativePrice;

      final updatedBuyUrl = alternativeMatch == null
          ? AffiliateLinkService.attachAffiliateTag(product.buyUrl)
          : AffiliateLinkService.attachAffiliateTag(alternativeMatch.link);

      final updatedTags = _updatedDynamicTags(
        product.tags,
        expensivePrice: expensivePrice,
        alternativePrice: alternativePrice,
      );

      if (expensivePrice == product.expensivePrice &&
          alternativePrice == product.alternativePrice &&
          updatedBuyUrl == product.buyUrl &&
          sameStringLists(updatedTags, product.tags)) {
        return product;
      }

      return product.copyWith(
        expensivePrice: expensivePrice,
        alternativePrice: alternativePrice,
        buyUrl: updatedBuyUrl,
        tags: updatedTags,
      );
    } catch (_) {
      return product;
    }
  }

  String _buildExpensiveQuery(ProductComparison product) {
    return '${product.expensiveName} site:amazon.sa OR site:noon.com السعودية سعر';
  }

  String _buildAlternativeQuery(ProductComparison product) {
    return '${product.alternativeName} السعودية سعر '
        'site:noon.com OR site:amazon.sa OR site:nahdionline.com OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net';
  }

  SearchResultItem? _selectBestMatch(
    List<SearchResultItem> items, {
    required List<String> preferredHosts,
    bool requirePreferredHost = false,
  }) {
    SearchResultItem? best;
    var bestScore = -1;

    for (final item in items) {
      final uri = Uri.tryParse(item.link);
      if (uri == null) {
        continue;
      }

      final hasPreferredHost = preferredHosts.any(
        (host) => uri.host.contains(host),
      );
      if (requirePreferredHost && !hasPreferredHost) {
        continue;
      }

      var score = 0;
      for (final host in preferredHosts) {
        if (uri.host.contains(host)) {
          score += 10;
        }
      }
      if (_extractPrice(item.title, item.snippet) != null) {
        score += 5;
      }

      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }

    return best;
  }

  double? _extractPrice(String title, String snippet) {
    final text = '$title $snippet'.replaceAll(',', '');
    final patterns = [
      RegExp(r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false),
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }

    return null;
  }

  List<String> _updatedDynamicTags(
    List<String> tags, {
    required double expensivePrice,
    required double alternativePrice,
  }) {
    final filtered = tags
        .where(
          (tag) =>
              normalizeArabic(tag) !=
              normalizeArabic(LeastPriceDataConfig.originalOnSaleTag),
        )
        .toList();

    if (expensivePrice > 0 &&
        alternativePrice > 0 &&
        expensivePrice <= alternativePrice) {
      filtered.insert(0, LeastPriceDataConfig.originalOnSaleTag);
    }

    return filtered;
  }
}
