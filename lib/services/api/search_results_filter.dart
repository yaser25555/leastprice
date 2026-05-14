import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SearchResultsFilter {
  const SearchResultsFilter();

  static const Set<String> foodRelatedKeywords = {
    'مطعم', 'restaurant', 'قهوة', 'coffee', 'وجبة', 'meal',
    'أكل', 'food', 'مشروب', 'drink', 'برجر', 'burger',
    'بيتزا', 'pizza', 'دجاج', 'chicken', 'لحم', 'meat',
    'حلويات', 'sweets', 'كيك', 'cake', 'عصير', 'juice',
    'رز', 'ارز', 'شعير', 'مصري', 'شاي', 'tea',
    'مكولات', 'snacks',
  };

  bool isFoodRelatedQuery(String query) {
    final normalized = normalizeArabic(query.toLowerCase());
    return foodRelatedKeywords.any((keyword) => normalized.contains(keyword));
  }

  List<ComparisonSearchResult> filterSupportedSaudiStoreResults(
    List<ComparisonSearchResult> results, {
    String? targetStoreId,
  }) {
    if (results.isEmpty) return results;

    final filtered = results.toList(growable: false);

    if (targetStoreId != null && targetStoreId.trim().isNotEmpty) {
      final strictMatches = filtered
          .where((result) => _matchesTargetStore(result, targetStoreId))
          .toList(growable: false);
      strictMatches.sort(_compareSearchResults);
      return strictMatches;
    }

    filtered.sort(_compareSearchResults);
    return filtered;
  }

  bool _matchesTargetStore(
    ComparisonSearchResult result,
    String targetStoreId,
  ) {
    final normalizedTarget = targetStoreId.trim().toLowerCase();
    if (normalizedTarget.isEmpty) return false;

    if (result.storeId.trim().toLowerCase() == normalizedTarget) return true;

    final inferredStoreId = inferStoreIdFromUrl(
      result.productUrl,
      fallbackName: result.storeName,
    );
    if ((inferredStoreId ?? '').trim().toLowerCase() == normalizedTarget) {
      return true;
    }

    final targetDomain = domainForStoreId(normalizedTarget);
    final resultHost = hostFromUrl(result.productUrl)?.toLowerCase() ?? '';
    if (targetDomain != null &&
        targetDomain.isNotEmpty &&
        resultHost.contains(targetDomain.toLowerCase())) {
      return true;
    }

    return false;
  }

  int _affiliatePriority(ComparisonSearchResult result) {
    final hasAffiliate =
        AffiliateLinkService.hasAffiliateProgram(result.productUrl);
    final hasCoupon = result.matchedCoupon != null;
    if (hasAffiliate && hasCoupon) return 0;
    if (hasAffiliate) return 1;
    if (hasCoupon) return 2;
    return 3;
  }

  int _compareSearchResults(
    ComparisonSearchResult first,
    ComparisonSearchResult second,
  ) {
    final firstPriority = _affiliatePriority(first);
    final secondPriority = _affiliatePriority(second);
    if (firstPriority != secondPriority) {
      return firstPriority.compareTo(secondPriority);
    }

    final priceCompare = first.price.compareTo(second.price);
    if (priceCompare != 0) return priceCompare;

    if (first.isLiveDirect != second.isLiveDirect) {
      return first.isLiveDirect ? -1 : 1;
    }

    return first.storeName.compareTo(second.storeName);
  }
}
