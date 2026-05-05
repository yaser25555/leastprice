import 'package:leastprice/data/models/product_comparison.dart';

class CatalogRefreshResult {
  const CatalogRefreshResult({
    required this.products,
    this.notice,
  });

  final List<ProductComparison> products;
  final String? notice;
}
