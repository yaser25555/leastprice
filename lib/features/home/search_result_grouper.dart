import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/grouped_product_card.dart';

class SearchResultGrouper {
  static List<GroupedProductCard> group(
      List<ComparisonSearchResult> results) {
    if (results.isEmpty) return [];

    final groups = <List<ComparisonSearchResult>>[];

    for (final candidate in results) {
      final candidateTokens = _tokenSet(candidate.title);
      bool matched = false;

      for (final group in groups) {
        if (group.isEmpty) continue;
        final groupTokens = _tokenSet(group.first.title);
        if (_jaccard(candidateTokens, groupTokens) >= 0.4) {
          group.add(candidate);
          matched = true;
          break;
        }
      }

      if (!matched) {
        groups.add([candidate]);
      }
    }

    return groups.map((offers) {
      offers.sort((a, b) => a.price.compareTo(b.price));

      final bestOffer = offers.first;
      final bestCoupon = offers
          .where((o) => o.matchedCoupon != null)
          .map((o) => o.matchedCoupon!)
          .fold<Coupon?>(null, (best, c) {
        if (best == null) return c;
        if ((c.discountPercent ?? 0) > (best.discountPercent ?? 0)) return c;
        return best;
      });

      return GroupedProductCard(
        displayTitle: _bestTitle(offers),
        displayImageUrl: bestOffer.imageUrl,
        offers: offers,
        matchedCoupon: bestCoupon,
      );
    }).toList();
  }

  static String _bestTitle(List<ComparisonSearchResult> offers) {
    final titleCounts = <String, int>{};
    for (final o in offers) {
      final clean = o.title.trim();
      titleCounts[clean] = (titleCounts[clean] ?? 0) + 1;
    }
    return titleCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  static Set<String> _tokenSet(String title) {
    final normalized = normalizeArabic(title.toLowerCase());
    return normalized
        .split(RegExp(r'[\s,.\-–—/|:;()\[\]{}]+'))
        .where((t) => t.length >= 2)
        .toSet();
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }
}
