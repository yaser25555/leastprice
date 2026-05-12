import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SearchResultsFilter {
  const SearchResultsFilter();

  static const Set<String> saudiSupportedStoreIds = {
    'amazon',
    'noon',
    'hungerstation',
    'panda',
    'othaim',
    'almazraa',
    'lulu',
    'carrefour',
    'tamimi',
    'danube',
    'bindawood',
    'toyou',
    'keeta',
    'nahdi',
    'aldawaa',
    'jarir',
    'extra',
    'namshi',
    'ntshop',
    'ikea',
    'saco',
    'niceone',
    'goldenscent',
    'abyat',
    'homecentre',
  };

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
    final filtered = results.where((result) {
      final normalizedStoreId = result.storeId.trim().toLowerCase();

      if (targetStoreId != null &&
          targetStoreId.trim().isNotEmpty &&
          normalizedStoreId == targetStoreId.trim().toLowerCase()) {
        return true;
      }

      final productHost =
          hostFromUrl(result.productUrl)?.toLowerCase() ?? '';
      final storeNameLower = result.storeName.toLowerCase();
      final storeIdLower = normalizedStoreId.toLowerCase();

      if (saudiSupportedStoreIds.contains(storeIdLower)) return true;

      final inferredId =
          inferStoreIdFromUrl('', fallbackName: result.storeName);
      if (inferredId != null &&
          saudiSupportedStoreIds.contains(inferredId)) {
        return true;
      }

      if (productHost.contains('panda.sa') ||
          productHost.contains('noon.com') ||
          productHost.contains('amazon.sa') ||
          productHost.contains('othaim') ||
          productHost.contains('lulu') ||
          productHost.contains('carrefour') ||
          productHost.contains('danube') ||
          productHost.contains('bindawood') ||
          productHost.contains('tamimi')) {
        return true;
      }

      if (productHost.contains('google')) {
        if (storeNameLower.length > 2 && !storeNameLower.contains('http')) {
          return true;
        }
      }

      return false;
    }).toList(growable: false);

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

  int _compareSearchResults(
    ComparisonSearchResult first,
    ComparisonSearchResult second,
  ) {
    final priceDifference = (first.price - second.price).abs();
    final minPrice = first.price < second.price ? first.price : second.price;

    final tolerance = (minPrice * 0.05).clamp(2.0, 15.0);

    if (priceDifference <= tolerance &&
        first.isPreferredMarketplace != second.isPreferredMarketplace) {
      return first.isPreferredMarketplace ? -1 : 1;
    }

    final priceCompare = first.price.compareTo(second.price);
    if (priceCompare != 0) return priceCompare;

    if (first.isPreferredMarketplace != second.isPreferredMarketplace) {
      return first.isPreferredMarketplace ? -1 : 1;
    }

    if (first.isLiveDirect != second.isLiveDirect) {
      return first.isLiveDirect ? -1 : 1;
    }

    return first.storeName.compareTo(second.storeName);
  }
}
