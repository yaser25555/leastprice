import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/data/models/comparison_search_response.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/comparison_search_cache_entry.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SerpApiShoppingSearchService {
  const SerpApiShoppingSearchService({
    FirestoreCatalogService? catalogService,
  }) : _catalogService = catalogService;

  final FirestoreCatalogService? _catalogService;

  FirestoreCatalogService get _service =>
      _catalogService ?? const FirestoreCatalogService();
  static const Set<String> _saudiSupportedStoreIds = {
    'amazon',
    'noon',
    'hungerstation',
    'panda',
    'othaim',
    'almazraa',
    'lulu',
    'carrefour',
    'tamimi',
    'toyou',
    'keeta',
    'nahdi',
    'aldawaa',
    'jarir',
    'extra',
  };

  ComparisonSearchResponse _buildResponse({
    required List<ComparisonSearchResult> results,
    required bool fromCache,
    String? notice,
  }) {
    final serpApiResultsCount = results
        .where(
          (result) => result.sourceType == ComparisonSearchSourceType.serpApi,
        )
        .length;
    final scrapedResultsCount = results
        .where(
          (result) => result.sourceType == ComparisonSearchSourceType.scraper,
        )
        .length;

    return ComparisonSearchResponse(
      results: results,
      fromCache: fromCache,
      notice: notice,
      serpApiResultsCount: serpApiResultsCount,
      scrapedResultsCount: scrapedResultsCount,
    );
  }

  Future<ComparisonSearchResponse> search({
    required String query,
    required bool firebaseReady,
    required MarketplaceSearchCity city,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();
    final normalizedQuery = normalizeArabic(trimmedQuery);
    if (normalizedQuery.length < 2) {
      return const ComparisonSearchResponse(
        results: <ComparisonSearchResult>[],
        fromCache: false,
      );
    }

    final canUseFirestoreCache = firebaseReady && !kIsWeb;
    ComparisonSearchCacheEntry? cachedEntry;
    if (canUseFirestoreCache) {
      try {
        cachedEntry = await _service.fetchComparisonSearchCache(
          trimmedQuery,
          locationKey: city.id,
        );
      } catch (error) {
        debugPrint('LeastPrice comparison cache read skipped: $error');
      }
    }

    final apiKey = LeastPriceDataConfig.serpApiKey.trim();
    if (apiKey.isEmpty) {
      return ComparisonSearchResponse(
        results: cachedEntry?.results ?? const <ComparisonSearchResult>[],
        fromCache: cachedEntry != null,
        notice: tr(
          'عذراً، لم نجد نتائج حالياً',
          'Sorry, we could not find results right now.',
        ),
      );
    }

    try {
      final results = await _fetchLiveResults(
        trimmedQuery,
        apiKey,
        city: city,
      );
      if (canUseFirestoreCache && results.isNotEmpty) {
        try {
          await _service.saveComparisonSearchCache(
            query: trimmedQuery,
            results: results,
            locationKey: city.id,
            locationLabel: city.label,
          );
        } catch (error) {
          debugPrint('LeastPrice comparison cache save skipped: $error');
        }
      }

      return _buildResponse(
        results: results,
        fromCache: false,
        notice: results.isEmpty
            ? tr(
                'عذراً، لم نجد نتائج حالياً',
                'Sorry, we could not find results right now.',
              )
            : tr(
                'تم تحديث النتائج الحية مباشرة حسب مدينة ${city.label}.',
                'Live results were refreshed based on ${city.label}.',
              ),
      );
    } catch (_) {
      if (cachedEntry != null && cachedEntry.results.isNotEmpty) {
        return _buildResponse(
          results: cachedEntry.results,
          fromCache: true,
          notice: tr(
            'تعذر تحديث النتائج الحية حالياً، لذلك نعرض آخر نتائج محفوظة لهذه المدينة.',
            'Live refresh failed, so the latest saved results for this city are shown.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<List<ComparisonSearchResult>> _fetchLiveResults(
    String query,
    String apiKey, {
    required MarketplaceSearchCity city,
  }) async {
    final serperApiKey = LeastPriceDataConfig.serperApiKey.trim();
    final results = <ComparisonSearchResult>[];

    if (kIsWeb) {
      final uri = Uri.parse(
        '${Uri.base.origin}/api/${LeastPriceDataConfig.hybridSearchFunctionName}'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&hl=${isAr ? 'ar' : 'en'}'
        '&location=${Uri.encodeQueryComponent(city.serpApiLocation)}',
      );

      final response = await http.get(
        uri,
        headers: {
          if (apiKey.trim().isNotEmpty) 'x-serpapi-key': apiKey.trim(),
          'accept': 'application/json',
        },
      );
      if (response.statusCode >= 400) {
        throw Exception(
            'Hybrid marketplace search responded with ${response.statusCode}');
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Unexpected hybrid search payload');
      }

      final rows = payload['results'];
      final hybridResults = rows is List
          ? rows
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
              .toList()
          : <ComparisonSearchResult>[];

      final filteredHybridResults =
          _filterSupportedSaudiStoreResults(hybridResults);
      filteredHybridResults.sort(_compareSearchResults);
      return filteredHybridResults;
    }

    // Fetch from SerpApi
    final serpApiResults = await _fetchSerpApiResults(query, apiKey, city: city);
    results.addAll(serpApiResults);

    // Fetch from Serper if key is available
    if (serperApiKey.isNotEmpty) {
      try {
        final serperResults = await _fetchSerperResults(query, serperApiKey, city: city);
        results.addAll(serperResults);
      } catch (error) {
        debugPrint('Serper search failed: $error');
      }
    }

    final filteredResults = _filterSupportedSaudiStoreResults(results)
      ..sort(_compareSearchResults);

    return filteredResults;
  }

  Future<List<ComparisonSearchResult>> _fetchSerpApiResults(
    String query,
    String apiKey, {
    required MarketplaceSearchCity city,
  }) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google_shopping',
      'q': query,
      'location': city.serpApiLocation,
      'gl': 'sa',
      'hl': 'ar',
      'api_key': apiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      throw Exception('SerpApi responded with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected SerpApi payload');
    }

    return _parseResults(payload);
  }

  Future<List<ComparisonSearchResult>> _fetchSerperResults(
    String query,
    String apiKey, {
    required MarketplaceSearchCity city,
  }) async {
    final response = await http.post(
      Uri.parse('https://google.serper.dev/search'),
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'q': '$query shopping',
        'gl': 'sa',
        'hl': 'ar',
        'location': city.serpApiLocation,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Serper responded with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Serper payload');
    }

    return _parseSerperResults(payload);
  }

  List<ComparisonSearchResult> _parseResults(Map<String, dynamic> payload) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) {
        return;
      }

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
      if (!seen.add(fingerprint)) {
        return;
      }

      results.add(item);
    }

    final directResults = payload['shopping_results'];
    if (directResults is List) {
      for (final item in directResults) {
        if (item is! Map) {
          continue;
        }

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
        if (category is! Map) {
          continue;
        }
        final categoryItems = category['shopping_results'];
        if (categoryItems is! List) {
          continue;
        }
        for (final item in categoryItems) {
          if (item is! Map) {
            continue;
          }
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

  List<ComparisonSearchResult> _parseSerperResults(Map<String, dynamic> payload) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) {
        return;
      }

      final item = rawItem as Map<String, dynamic>;
      final title = stringValue(item['title'])?.trim() ?? '';
      final link = stringValue(item['link'])?.trim() ?? '';
      final snippet = stringValue(item['snippet'])?.trim() ?? '';

      if (title.isEmpty || link.isEmpty) {
        return;
      }

      final fingerprint = normalizeArabic('${title}|${link}');
      if (!seen.add(fingerprint)) {
        return;
      }

      // Try to extract price from snippet or title
      final priceText = extractMarketplacePrice(snippet) ?? extractMarketplacePrice(title);
      if (priceText == null) {
        return; // Skip if no price
      }

      final result = ComparisonSearchResult(
        title: title,
        price: priceText,
        storeName: inferStoreIdFromUrl(link) ?? 'Google Search',
        storeId: inferStoreIdFromUrl(link) ?? 'google',
        storeLogoUrl: resolveStoreLogoUrl(storeId: inferStoreIdFromUrl(link) ?? 'google', productUrl: link),
        imageUrl: '', // Serper may not have images
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi, // Treat as serpapi for now
        channelType: ComparisonSearchChannelType.marketplace,
        isLiveDirect: false,
      );

      results.add(result);
    }

    final organicResults = payload['organic'];
    if (organicResults is List) {
      for (final item in organicResults) {
        addResult(item);
      }
    }

    return results;
  }

  List<ComparisonSearchResult> _filterSupportedSaudiStoreResults(
    List<ComparisonSearchResult> results,
  ) {
    return results.where((result) {
      final normalizedStoreId = result.storeId.trim().toLowerCase();
      final productHost = hostFromUrl(result.productUrl)?.toLowerCase() ?? '';
      if (normalizedStoreId.isEmpty || normalizedStoreId == 'unknown') {
        return true;
      }
      if (_saudiSupportedStoreIds.contains(normalizedStoreId)) {
        return true;
      }
      if (normalizedStoreId.contains('google') || productHost.contains('google')) {
        return true;
      }
      return false;
    }).toList(growable: false);
  }

  int _compareSearchResults(
    ComparisonSearchResult first,
    ComparisonSearchResult second,
  ) {
    final priceDifference = (first.price - second.price).abs();
    if (priceDifference <= 2.0 &&
        first.isPreferredMarketplace != second.isPreferredMarketplace) {
      return first.isPreferredMarketplace ? -1 : 1;
    }

    final priceCompare = first.price.compareTo(second.price);
    if (priceCompare != 0) {
      return priceCompare;
    }

    if (first.isPreferredMarketplace != second.isPreferredMarketplace) {
      return first.isPreferredMarketplace ? -1 : 1;
    }

    if (first.isLiveDirect != second.isLiveDirect) {
      return first.isLiveDirect ? -1 : 1;
    }

    return first.storeName.compareTo(second.storeName);
  }
}
