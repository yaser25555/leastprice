import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/coupon.dart';

class GroupedProductCard {
  const GroupedProductCard({
    required this.displayTitle,
    required this.displayImageUrl,
    required this.offers,
    this.matchedCoupon,
  });

  final String displayTitle;
  final String displayImageUrl;
  final List<ComparisonSearchResult> offers;
  final Coupon? matchedCoupon;

  double get lowestPrice => offers
      .map((o) => o.price)
      .reduce((a, b) => a < b ? a : b);

  String get currency => offers.first.currency;

  String get uniqueKey {
    final parts = <String>[];
    for (final o in offers.take(3)) {
      if (o.storeId.isNotEmpty) parts.add(o.storeId);
      if (o.price > 0) parts.add(o.price.toStringAsFixed(0));
    }
    final suffix = parts.isNotEmpty ? '__${parts.join('_')}' : '';
    return '${displayTitle.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '_')}$suffix';
  }
}
