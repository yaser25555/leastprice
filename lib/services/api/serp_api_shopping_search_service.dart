import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/data/models/comparison_search_response.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/comparison_search_cache_entry.dart';
import 'package:leastprice/services/preferences/local_search_cache_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SerpApiShoppingSearchService {
  const SerpApiShoppingSearchService({
    FirestoreCatalogService? catalogService,
  }) : _catalogService = catalogService;

  final FirestoreCatalogService? _catalogService;

  FirestoreCatalogService get _service =>
      _catalogService ?? const FirestoreCatalogService();
  final LocalSearchCacheService _localCache = const LocalSearchCacheService();
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

  static const Set<String> _foodRelatedKeywords = {
    'مطعم',
    'restaurant',
    'قهوة',
    'coffee',
    'وجبة',
    'meal',
    'أكل',
    'food',
    'مشروب',
    'drink',
    'برجر',
    'burger',
    'بيتزا',
    'pizza',
    'دجاج',
    'chicken',
    'لحم',
    'meat',
    'حلويات',
    'sweets',
    'كيك',
    'cake',
    'عصير',
    'juice',
    'شاي',
    'tea',
    'مكولات',
    'snacks',
  };

  bool _isFoodRelatedQuery(String query) {
    final normalized = normalizeArabic(query.toLowerCase());
    return _foodRelatedKeywords.any((keyword) => normalized.contains(keyword));
  }

  ComparisonSearchResponse _buildResponse({
    required List<ComparisonSearchResult> results,
    required bool fromCache,
    String? notice,
    String? effectiveQuery,
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
      effectiveQuery: effectiveQuery,
    );
  }

  Future<ComparisonSearchResponse> search({
    required String query,
    required bool firebaseReady,
    required MarketplaceSearchCity city,
    bool forceRefresh = false,
    String? targetStoreId,
    int startOffset = 0,
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

    // 1. Try Local Cache (Fastest, Zero Cost)
    if (!forceRefresh && startOffset == 0) {
      try {
        cachedEntry = await _localCache.fetchLocalSearchCache(
          trimmedQuery,
          locationKey: city.id,
          targetStoreId: targetStoreId,
        );
        if (cachedEntry != null &&
            cachedEntry.results.isNotEmpty &&
            cachedEntry.isFresh) {
          return ComparisonSearchResponse(
            results: cachedEntry.results,
            fromCache: true,
            notice: tr(
              'نتائج محفوظة من جهازك • ${city.label}',
              'Saved results from your device • ${city.label}',
            ),
          );
        }
      } catch (error) {
        debugPrint('LeastPrice local cache read skipped: $error');
      }
    }

    // 2. Try Firestore Cache
    if (canUseFirestoreCache && !forceRefresh && startOffset == 0) {
      try {
        cachedEntry = await _service.fetchComparisonSearchCache(
          trimmedQuery,
          locationKey: city.id,
          targetStoreId: targetStoreId,
        );
        if (cachedEntry != null &&
            cachedEntry.results.isNotEmpty &&
            cachedEntry.isFresh) {
          // Save to local cache for next time
          await _localCache.saveLocalSearchCache(
            query: trimmedQuery,
            results: cachedEntry.results,
            locationKey: city.id,
            targetStoreId: targetStoreId,
          );
          return ComparisonSearchResponse(
            results: cachedEntry.results,
            fromCache: true,
            notice: tr(
              'نتائج محفوظة • ${city.label}',
              'Cached results • ${city.label}',
            ),
          );
        }
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

    final serperApiKey = LeastPriceDataConfig.serperApiKey.trim();
    String effectiveQuery = trimmedQuery;

    // -- BARCODE TRANSLATION --
    if (RegExp(r'^[0-9]{8,14}$').hasMatch(effectiveQuery) &&
        serperApiKey.isNotEmpty) {
      effectiveQuery = await _translateBarcode(effectiveQuery, serperApiKey);
    }

    try {
      final results = await _fetchLiveResults(
        effectiveQuery,
        apiKey,
        city: city,
        targetStoreId: targetStoreId,
        startOffset: startOffset,
      );
      if (results.isNotEmpty && startOffset == 0) {
        // Save to Local Cache
        try {
          await _localCache.saveLocalSearchCache(
            query: trimmedQuery,
            results: results,
            locationKey: city.id,
            targetStoreId: targetStoreId,
          );
        } catch (error) {
          debugPrint('LeastPrice local cache save skipped: $error');
        }

        // Save to Firestore Cache
        if (canUseFirestoreCache) {
          try {
            await _service.saveComparisonSearchCache(
              query: trimmedQuery,
              results: results,
              locationKey: city.id,
              locationLabel: city.label,
              targetStoreId: targetStoreId,
            );
          } catch (error) {
            debugPrint('LeastPrice comparison cache save skipped: $error');
          }
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
        effectiveQuery: effectiveQuery,
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

  Future<String> _translateBarcode(String barcode, String serperApiKey) async {
    try {
      final uri = Uri.https('google.serper.dev', '/search');
      final response = await http.post(
        uri,
        headers: {
          'X-API-KEY': serperApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': barcode,
          'gl': 'sa',
          'hl': 'ar',
        }),
      );
      if (response.statusCode < 400) {
        final payload = jsonDecode(response.body);
        final organic = payload['organic'];
        if (organic is List && organic.isNotEmpty) {
          final title = stringValue(organic.first['title']) ?? '';
          final snippet = stringValue(organic.first['snippet']) ?? '';

          // Smarter title cleaning:
          String cleanTitle = title
              .replaceAll(
                  RegExp(
                      r'(بنده|بندة|Panda|العثيم|Othaim|كارفور|Carrefour|التميمي|Tamimi|لولو|Lulu|نون|Noon|امازون|Amazon|Jarir|جرير|Extra|اكسترا)',
                      caseSensitive: false),
                  '')
              .split(RegExp(r'[|\-–]'))
              .where((s) => s.trim().length > 3)
              .join(' ')
              .trim();

          if (cleanTitle.length < 5 && snippet.isNotEmpty) {
            cleanTitle = snippet.split(RegExp(r'[.\-–]')).first.trim();
          }

          if (cleanTitle.isNotEmpty && !RegExp(r'^\d+$').hasMatch(cleanTitle)) {
            return cleanTitle;
          }
        }
      }
    } catch (error) {
      debugPrint('Barcode translation via Serper failed: $error');
    }
    return barcode;
  }

  Future<List<ComparisonSearchResult>> _fetchLiveResults(
    String effectiveQuery,
    String apiKey, {
    required MarketplaceSearchCity city,
    String? targetStoreId,
    int startOffset = 0,
  }) async {
    final serperApiKey = LeastPriceDataConfig.serperApiKey.trim();
    final results = <ComparisonSearchResult>[];

    // Let local filtering handle the store filter to avoid breaking Google Shopping query

    if (kIsWeb) {
      final origin = Uri.base.origin;
      final isLocalhost =
          origin.contains('localhost') || origin.contains('127.0.0.1');
      final baseUrl = isLocalhost
          ? 'https://${LeastPriceDataConfig.functionsRegion}-leastprice-yaser.cloudfunctions.net/${LeastPriceDataConfig.hybridSearchFunctionName}'
          : '$origin/api/${LeastPriceDataConfig.hybridSearchFunctionName}';

      final pageNum = (startOffset / 20).floor() + 1;
      final uri = Uri.parse(
        '$baseUrl'
        '?q=${Uri.encodeQueryComponent(effectiveQuery)}'
        '&hl=${isAr ? 'ar' : 'en'}'
        '&location=${Uri.encodeQueryComponent(city.serpApiLocation)}'
        '&page=$pageNum',
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

      final filteredHybridResults = _filterSupportedSaudiStoreResults(
          hybridResults,
          targetStoreId: targetStoreId);
      filteredHybridResults.sort(_compareSearchResults);
      return filteredHybridResults;
    }

    // Fetch from SerpApi
    final serpApiResults = await _fetchSerpApiResults(effectiveQuery, apiKey,
        city: city, startOffset: startOffset);
    results.addAll(serpApiResults);

    // Fetch from Serper if key is available
    if (serperApiKey.isNotEmpty) {
      try {
        final pageNum = (startOffset / 10).floor() + 1;
        final serperResults = await _fetchSerperResults(
            effectiveQuery, serperApiKey,
            city: city, page: pageNum);
        results.addAll(serperResults);
      } catch (error) {
        debugPrint('Serper search failed: $error');
      }
    }

    // Fetch from Google Local if food-related query
    if (_isFoodRelatedQuery(effectiveQuery)) {
      try {
        final localResults =
            await _fetchLocalResults(effectiveQuery, apiKey, city: city);
        results.addAll(localResults);
      } catch (error) {
        debugPrint('Google Local search failed: $error');
      }
    }

    final filteredResults =
        _filterSupportedSaudiStoreResults(results, targetStoreId: targetStoreId)
          ..sort(_compareSearchResults);

    return filteredResults;
  }

  Future<List<ComparisonSearchResult>> _fetchSerpApiResults(
    String query,
    String apiKey, {
    required MarketplaceSearchCity city,
    int startOffset = 0,
  }) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google_shopping',
      'q': query,
      'location': city.serpApiLocation,
      'gl': 'sa',
      'hl': 'ar',
      'api_key': apiKey,
      'start': startOffset.toString(),
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
    int page = 1,
  }) async {
    final uri = Uri.https('google.serper.dev', '/shopping');
    final response = await http.post(
      uri,
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'q': query,
        'gl': 'sa',
        'hl': 'ar',
        'location': city.serpApiLocation,
        'page': page,
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

  List<ComparisonSearchResult> _parseLocalResults(
      Map<String, dynamic> payload) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) {
        return;
      }

      final item = rawItem as Map<String, dynamic>;
      final title = stringValue(item['title'])?.trim() ?? '';
      final link = stringValue(item['link'])?.trim() ?? '';

      if (title.isEmpty || link.isEmpty) {
        return;
      }

      final fingerprint = normalizeArabic('$title|$link');
      if (!seen.add(fingerprint)) {
        return;
      }

      // For local results, price might not be available, set to 0 or estimate
      final price = 0.0; // Local results may not have prices

      final result = ComparisonSearchResult(
        title: title,
        price: price,
        storeName: title,
        storeId: inferStoreIdFromUrl(link) ?? 'local',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'local', productUrl: link),
        imageUrl: stringValue(item['thumbnail']) ?? '',
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType:
            ComparisonSearchChannelType.delivery, // Assume delivery for food
        isLiveDirect: false,
        tag: 'عرض وجبة', // Tag for food deals
      );

      results.add(result);
    }

    final localResults = payload['local_results'];
    if (localResults is List) {
      for (final item in localResults) {
        addResult(item);
      }
    }

    return results;
  }

  Future<List<ComparisonSearchResult>> _fetchLocalResults(
    String query,
    String apiKey, {
    required MarketplaceSearchCity city,
  }) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google_local',
      'q': query,
      'location': city.serpApiLocation,
      'gl': 'sa',
      'hl': 'ar',
      'api_key': apiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      throw Exception('SerpApi Local responded with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected SerpApi Local payload');
    }

    return _parseLocalResults(payload);
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

  List<ComparisonSearchResult> _parseSerperResults(
      Map<String, dynamic> payload) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addOrganicResult(dynamic rawItem) {
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

      final fingerprint = normalizeArabic('$title|$link');
      if (!seen.add(fingerprint)) {
        return;
      }

      // Try to extract price from snippet or title
      final priceText =
          extractMarketplacePrice(snippet) ?? extractMarketplacePrice(title);
      if (priceText == null) {
        return; // Skip if no price
      }

      final result = ComparisonSearchResult(
        title: title,
        price: priceText,
        storeName: inferStoreIdFromUrl(link) ?? 'Google Search',
        storeId: inferStoreIdFromUrl(link) ?? 'google',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'google', productUrl: link),
        imageUrl: '', // Serper may not have images in organic
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType: ComparisonSearchChannelType.marketplace,
        isLiveDirect: false,
      );

      results.add(result);
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

      final result = ComparisonSearchResult(
        title: title,
        price: priceValue,
        storeName: source.isNotEmpty
            ? source
            : (inferStoreIdFromUrl(link) ?? 'Google Shopping'),
        storeId: inferStoreIdFromUrl(link) ?? 'google',
        storeLogoUrl: resolveStoreLogoUrl(
            storeId: inferStoreIdFromUrl(link) ?? 'google', productUrl: link),
        imageUrl: imageUrl,
        productUrl: link,
        currency: 'SAR',
        sourceType: ComparisonSearchSourceType.serpApi,
        channelType: ComparisonSearchChannelType.marketplace,
        isLiveDirect: false,
      );

      results.add(result);
    }

    // Try parsing shopping results first (more accurate)
    final shoppingResults = payload['shopping'];
    if (shoppingResults is List) {
      for (final item in shoppingResults) {
        addShoppingResult(item);
      }
    }

    // Fallback to organic results
    final organicResults = payload['organic'];
    if (organicResults is List) {
      for (final item in organicResults) {
        addOrganicResult(item);
      }
    }

    return results;
  }

  List<ComparisonSearchResult> _filterSupportedSaudiStoreResults(
    List<ComparisonSearchResult> results, {
    String? targetStoreId,
  }) {
    final filtered = results.where((result) {
      final normalizedStoreId = result.storeId.trim().toLowerCase();

      // Always show results from the explicitly selected store if they match
      if (targetStoreId != null &&
          targetStoreId.trim().isNotEmpty &&
          normalizedStoreId == targetStoreId.trim().toLowerCase()) {
        return true;
      }

      // If we are looking for a specific store, we still show other supported stores
      // but they will be sorted lower later. This ensures 'No Results' is avoided.
      final productHost = hostFromUrl(result.productUrl)?.toLowerCase() ?? '';
      if (normalizedStoreId.isEmpty || normalizedStoreId == 'unknown') {
        return false;
      }
      if (_saudiSupportedStoreIds.contains(normalizedStoreId)) {
        return true;
      }
      if (normalizedStoreId.contains('google') ||
          productHost.contains('google')) {
        return true;
      }
      return false;
    }).toList(growable: false);

    // If a target store is selected, we perform a special sort:
    // 1. Target store results first.
    // 2. Then by price.
    if (targetStoreId != null && targetStoreId.trim().isNotEmpty) {
      final target = targetStoreId.trim().toLowerCase();
      filtered.sort((a, b) {
        final aMatch = a.storeId.toLowerCase() == target;
        final bMatch = b.storeId.toLowerCase() == target;
        if (aMatch != bMatch) {
          return aMatch ? -1 : 1;
        }
        return _compareSearchResults(a, b);
      });
    } else {
      filtered.sort(_compareSearchResults);
    }

    return filtered;
  }

  int _compareSearchResults(
    ComparisonSearchResult first,
    ComparisonSearchResult second,
  ) {
    final priceDifference = (first.price - second.price).abs();
    final minPrice = first.price < second.price ? first.price : second.price;

    // Give preferred stores a small tolerance (5% of the price or up to 15 SAR)
    // to bubble them to the top if they are extremely close to the lowest price.
    final tolerance = (minPrice * 0.05).clamp(2.0, 15.0);

    if (priceDifference <= tolerance &&
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
