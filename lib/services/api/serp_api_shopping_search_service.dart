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
import 'package:leastprice/services/api/search_results_parser.dart';
import 'package:leastprice/services/api/search_results_filter.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SerpApiShoppingSearchService {
  const SerpApiShoppingSearchService({
    FirestoreCatalogService? catalogService,
  }) : _catalogService = catalogService;

  final FirestoreCatalogService? _catalogService;

  FirestoreCatalogService get _service =>
      _catalogService ?? const FirestoreCatalogService();
  final LocalSearchCacheService _localCache = const LocalSearchCacheService();
  final SearchResultsParser _parser = const SearchResultsParser();
  final SearchResultsFilter _filter = const SearchResultsFilter();

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

    String effectiveQuery = trimmedQuery;

    try {
      final results = await _fetchHybridResults(
        effectiveQuery,
        city: city,
        targetStoreId: targetStoreId,
        startOffset: startOffset,
      );
      if (results.isNotEmpty && startOffset == 0) {
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
    } catch (e) {
      if (cachedEntry != null && cachedEntry.results.isNotEmpty) {
        return _buildResponse(
          results: cachedEntry.results,
          fromCache: true,
          notice: tr(
            'تعذر تحديث النتائج الحية ($e)، لذلك نعرض آخر نتائج محفوظة لهذه المدينة.',
            'Live refresh failed ($e), so the latest saved results for this city are shown.',
          ),
        );
      }
      return _buildResponse(
        results: [],
        fromCache: false,
        notice: 'Technical Error: $e',
        effectiveQuery: effectiveQuery,
      );
    }
  }

  Future<List<ComparisonSearchResult>> _fetchHybridResults(
    String effectiveQuery, {
    required MarketplaceSearchCity city,
    String? targetStoreId,
    int startOffset = 0,
  }) async {
    final baseUrl = _hybridSearchBaseUrl();
    final pageNum = (startOffset / 20).floor() + 1;
    final uri = Uri.parse(
      '$baseUrl'
      '?q=${Uri.encodeQueryComponent(effectiveQuery)}'
      '&hl=${isAr ? 'ar' : 'en'}'
      '&location=${Uri.encodeQueryComponent(city.serpApiLocation)}'
      '&page=$pageNum'
      '${targetStoreId != null && targetStoreId.trim().isNotEmpty ? '&store=${Uri.encodeQueryComponent(targetStoreId)}' : ''}',
    );

    final response = await http.get(
      uri,
      headers: {'accept': 'application/json'},
    ).timeout(const Duration(seconds: 25));
    if (response.statusCode >= 400) {
      throw Exception(
          'Hybrid marketplace search responded with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected hybrid search payload');
    }

    final debug = payload['debug'];
    if (debug is Map) {
      debugPrint('[Worker] hasSerpApiKey: ${debug['hasSerpApiKey']}, '
          'hasSerperApiKey: ${debug['hasSerperApiKey']}, '
          'serpApiResults: ${payload['counts']['serpApi']}, '
          'serperResults: ${payload['counts']['serper']}');
    }

    final rows = payload['results'];
    final hybridResults = rows is List
        ? _parser.parseHybridResponse(rows)
        : <ComparisonSearchResult>[];

    final filteredHybridResults = _filter.filterSupportedSaudiStoreResults(
      hybridResults,
      targetStoreId: targetStoreId,
    );
    return filteredHybridResults;
  }

  String _hybridSearchBaseUrl() {
    final override = LeastPriceDataConfig.hybridSearchBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/')
          ? override.substring(0, override.length - 1)
          : override;
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      final isLocalhost =
          origin.contains('localhost') || origin.contains('127.0.0.1');
      if (!isLocalhost) {
        return '$origin/api/${LeastPriceDataConfig.hybridSearchFunctionName}';
      }
    }

    return 'https://${LeastPriceDataConfig.functionsRegion}-leastprice-yaser.cloudfunctions.net/${LeastPriceDataConfig.hybridSearchFunctionName}';
  }

}
