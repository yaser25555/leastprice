
import 'package:leastprice/data/models/product_comparison.dart';

class SmartSearchDiscoveryResult {
  const SmartSearchDiscoveryResult({
    required this.products,
    this.notice,
  });

  final List<ProductComparison> products;
  final String? notice;
}
