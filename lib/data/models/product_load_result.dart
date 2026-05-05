import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ProductLoadResult {
  const ProductLoadResult({
    required this.products,
    required this.source,
    this.referralProfile,
    this.notice,
  });

  final List<ProductComparison> products;
  final ProductDataSource source;
  final UserSavingsProfile? referralProfile;
  final String? notice;
}
