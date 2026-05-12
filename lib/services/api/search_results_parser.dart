import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SearchResultsParser {
  const SearchResultsParser();

  List<ComparisonSearchResult> parseSerpApiShoppingResults(
    Map<String, dynamic> payload,
  ) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) return;

      final item = ComparisonSearchResult.fromJson(
        Map<String, dynamic>.from(rawItem),
      );
      if (item.title.trim().isEmpty ||
          item.productUrl.trim().isEmpty ||
          item.price <= 0) {
        return;
      }

      final fingerprint = normalizeArabic(
        '${item.title}|${item.storeName}|${item.price}',
      );
      if (!seen.add(fingerprint)) return;

      results.add(item);
    }

    final directResults = payload['shopping_results'];
    if (directResults is List) {
      for (final item in directResults) {
        if (item is! Map) continue;
        addResult({
          'title': item['title'],
          'price': item['price'],
          'priceValue': item['extracted_price'],
          'thumbnail': item['thumbnail'],
          'source': item['source'],
          'link': item['link'] ?? item['product_link'],
          'thumbnails': item['thumbnails'],
          'currency': item['currency'] ?? 'SAR',
        });
      }
    }

    final categorizedResults = payload['categorized_shopping_results'];
    if (categorizedResults is List) {
      for (final category in categorizedResults) {
        if (category is! Map) continue;
        final categoryItems = category['shopping_results'];
        if (categoryItems is! List) continue;
        for (final item in categoryItems) {
          if (item is! Map) continue;
          addResult({
            'title': item['title'],
            'price': item['price'],
            'priceValue': item['extracted_price'],
            'thumbnail': item['thumbnail'],
            'source': item['source'],
            'link': item['link'] ?? item['product_link'],
            'thumbnails': item['thumbnails'],
            'currency': item['currency'] ?? 'SAR',
          });
        }
      }
    }

    return results;
  }

  List<ComparisonSearchResult> parseSerperResults(
    Map<String, dynamic> payload,
  ) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addOrganicResult(dynamic rawItem) {
      if (rawItem is! Map) return;

      final item = rawItem as Map<String, dynamic>;
      final title = stringValue(item['title'])?.trim() ?? '';
      final link = stringValue(item['link'])?.trim() ?? '';
      final snippet = stringValue(item['snippet'])?.trim() ?? '';

      if (title.isEmpty || link.isEmpty) return;

      final fingerprint = normalizeArabic('$title|$link');
      if (!seen.add(fingerprint)) return;

      final priceText =
          extractMarketplacePrice(snippet) ?? extractMarketplacePrice(title);
      if (priceText == null) return;

      results.add(ComparisonSearchResult(
        title: title,
        price: priceText,
        storeName: inferStoreIdFromUrl(link) ?? 'Google Search',
        storeId: inferStoreIdFromUrl(link) ?? 'google',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'google', productUrl: link),
        imageUrl: '',
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType: ComparisonSearchChannelType.marketplace,
        isLiveDirect: false,
      ));
    }

    void addShoppingResult(dynamic rawItem) {
      if (rawItem is! Map) return;

      final item = rawItem as Map<String, dynamic>;
      final title = stringValue(item['title'])?.trim() ?? '';
      final link = stringValue(item['link'])?.trim() ?? '';
      final priceString = stringValue(item['price'])?.trim() ?? '';
      final imageUrl = stringValue(item['imageUrl'])?.trim() ?? '';
      final source = stringValue(item['source'])?.trim() ?? '';

      if (title.isEmpty || link.isEmpty || priceString.isEmpty) return;

      final fingerprint = normalizeArabic('$title|$link');
      if (!seen.add(fingerprint)) return;

      final priceValue = extractMarketplacePrice(priceString);
      if (priceValue == null || priceValue <= 0) return;

      results.add(ComparisonSearchResult(
        title: title,
        price: priceValue,
        storeName: source.isNotEmpty
            ? source
            : (inferStoreIdFromUrl(link) ?? 'Google Shopping'),
        storeId: inferStoreIdFromUrl(link) ?? 'google',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'google',
            productUrl: link),
        imageUrl: imageUrl,
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType: ComparisonSearchChannelType.marketplace,
        isLiveDirect: false,
      ));
    }

    final shoppingResults = payload['shopping'];
    if (shoppingResults is List) {
      for (final item in shoppingResults) {
        addShoppingResult(item);
      }
    }

    final organicResults = payload['organic'];
    if (organicResults is List) {
      for (final item in organicResults) {
        addOrganicResult(item);
      }
    }

    return results;
  }

  List<ComparisonSearchResult> parseLocalResults(
    Map<String, dynamic> payload,
  ) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) return;

      final item = rawItem as Map<String, dynamic>;
      final title = stringValue(item['title'])?.trim() ?? '';
      final link = stringValue(item['link'])?.trim() ?? '';

      if (title.isEmpty || link.isEmpty) return;

      final fingerprint = normalizeArabic('$title|$link');
      if (!seen.add(fingerprint)) return;

      results.add(ComparisonSearchResult(
        title: title,
        price: 0.0,
        storeName: title,
        storeId: inferStoreIdFromUrl(link) ?? 'local',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'local', productUrl: link),
        imageUrl: stringValue(item['thumbnail']) ?? '',
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType: ComparisonSearchChannelType.delivery,
        isLiveDirect: false,
        tag: 'عرض وجبة',
      ));
    }

    final localResults = payload['local_results'];
    if (localResults is List) {
      for (final item in localResults) {
        addResult(item);
      }
    }

    return results;
  }

  List<ComparisonSearchResult> parseHybridResponse(
    List<dynamic> rows,
  ) {
    return rows
        .whereType<Map>()
        .map(
          (row) => ComparisonSearchResult.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .where(
          (result) =>
              result.title.trim().isNotEmpty &&
              result.productUrl.trim().isNotEmpty &&
              result.price > 0,
        )
        .toList();
  }
}
