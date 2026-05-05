import 'package:leastprice/data/models/comparison_search_result.dart';

class ComparisonSearchResponse {
  const ComparisonSearchResponse({
    required this.results,
    required this.fromCache,
    this.notice,
    this.serpApiResultsCount = 0,
    this.scrapedResultsCount = 0,
    this.effectiveQuery,
  });

  final List<ComparisonSearchResult> results;
  final bool fromCache;
  final String? notice;
  final int serpApiResultsCount;
  final int scrapedResultsCount;
  final String? effectiveQuery;

  ComparisonSearchResponse copyWith({
    List<ComparisonSearchResult>? results,
    bool? fromCache,
    String? notice,
    int? serpApiResultsCount,
    int? scrapedResultsCount,
    String? effectiveQuery,
  }) {
    return ComparisonSearchResponse(
      results: results ?? this.results,
      fromCache: fromCache ?? this.fromCache,
      notice: notice ?? this.notice,
      serpApiResultsCount: serpApiResultsCount ?? this.serpApiResultsCount,
      scrapedResultsCount: scrapedResultsCount ?? this.scrapedResultsCount,
      effectiveQuery: effectiveQuery ?? this.effectiveQuery,
    );
  }

  bool get hasLiveScrapedResults =>
      scrapedResultsCount > 0 || results.any((result) => result.isLiveDirect);
}
