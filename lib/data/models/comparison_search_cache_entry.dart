import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ComparisonSearchCacheEntry {
  const ComparisonSearchCacheEntry({
    required this.query,
    required this.normalizedQuery,
    required this.cachedAt,
    required this.results,
  });

  final String query;
  final String normalizedQuery;
  final DateTime cachedAt;
  final List<ComparisonSearchResult> results;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) <
      Duration(hours: LeastPriceDataConfig.comparisonSearchCacheHours);

  factory ComparisonSearchCacheEntry.fromJson(Map<String, dynamic> json) {
    final items = json['results'];
    return ComparisonSearchCacheEntry(
      query: stringValue(json['query']) ?? '',
      normalizedQuery: stringValue(json['normalizedQuery']) ?? '',
      cachedAt: dateTimeValue(json['cachedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      results: items is List
          ? items
              .whereType<Map>()
              .map(
                (item) => ComparisonSearchResult.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where(
                (result) =>
                    result.title.trim().isNotEmpty &&
                    result.productUrl.trim().isNotEmpty &&
                    result.price > 0,
              )
              .toList()
          : const <ComparisonSearchResult>[],
    );
  }
}
