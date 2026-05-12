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
}
