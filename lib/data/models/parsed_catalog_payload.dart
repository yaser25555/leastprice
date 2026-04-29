
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';

class ParsedCatalogPayload {
  const ParsedCatalogPayload({
    required this.products,
    this.referralProfile,
  });

  final List<ProductComparison> products;
  final UserSavingsProfile? referralProfile;
}
