import 'package:leastprice/data/models/comparison_search_result.dart';

class ComparisonSearchResponse {
  const ComparisonSearchResponse({
    required this.results,
    required this.fromCache,
    this.notice,
    this.serpApiResultsCount = 0,
    this.scrapedResultsCount = 0,
  });

  final List<ComparisonSearchResult> results;
  final bool fromCache;
  final String? notice;
  final int serpApiResultsCount;
  final int scrapedResultsCount;

  bool get hasLiveScrapedResults =>
      scrapedResultsCount > 0 || results.any((result) => result.isLiveDirect);
}
