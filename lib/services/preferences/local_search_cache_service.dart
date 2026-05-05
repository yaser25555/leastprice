import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/comparison_search_cache_entry.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';

class LocalSearchCacheService {
  const LocalSearchCacheService();

  static const String _cachePrefix = 'leastprice_search_';

  String _buildKey(String query, String? locationKey, String? targetStoreId) {
    final safeQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]+'), '_');
    final safeLocation = (locationKey ?? 'saudi_arabia').replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    final safeStore = (targetStoreId ?? 'all').replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    return '$_cachePrefix$safeLocation--$safeStore--$safeQuery';
  }

  Future<ComparisonSearchCacheEntry?> fetchLocalSearchCache(
    String query, {
    String? locationKey,
    String? targetStoreId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedQuery = normalizeArabic(query);
    final key = _buildKey(normalizedQuery, locationKey, targetStoreId);

    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      final cachedAtIso = json['cachedAt'] as String?;
      final cachedAt = cachedAtIso != null 
          ? DateTime.tryParse(cachedAtIso) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final entry = ComparisonSearchCacheEntry(
        query: stringValue(json['query']) ?? '',
        normalizedQuery: stringValue(json['normalizedQuery']) ?? '',
        cachedAt: cachedAt,
        results: (json['results'] as List?)
            ?.map((e) => ComparisonSearchResult.fromJson(e))
            .toList() ?? [],
      );

      if (!entry.isFresh) {
        await prefs.remove(key);
        return null;
      }
      return entry;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLocalSearchCache({
    required String query,
    required List<ComparisonSearchResult> results,
    String? locationKey,
    String? targetStoreId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedQuery = normalizeArabic(query);
    final key = _buildKey(normalizedQuery, locationKey, targetStoreId);

    final json = {
      'query': query,
      'normalizedQuery': normalizedQuery,
      'cachedAt': DateTime.now().toIso8601String(),
      'results': results.map((e) => e.toJson()).toList(),
    };

    await prefs.setString(key, jsonEncode(json));
  }
}
