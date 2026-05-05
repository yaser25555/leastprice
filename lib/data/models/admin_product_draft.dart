import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';

class AdminProductDraft {
  const AdminProductDraft({
    required this.referenceName,
    required this.referencePrice,
    required this.comparisonName,
    required this.comparisonPrice,
    required this.buyUrl,
    required this.categoryLabel,
  });

  final String referenceName;
  final double referencePrice;
  final String comparisonName;
  final double comparisonPrice;
  final String buyUrl;
  final String categoryLabel;

  ProductComparison toProductComparison() {
    final normalizedCategory = categoryLabel.trim();
    final normalizedUrl = AffiliateLinkService.normalizeContactLink(buyUrl);
    final normalizedReferenceName = referenceName.trim();
    final normalizedComparisonName = comparisonName.trim().isEmpty
        ? normalizedReferenceName
        : comparisonName.trim();
    return ProductComparison(
      categoryId: ProductCategoryCatalog.inferId(normalizedCategory),
      categoryLabel: normalizedCategory,
      expensiveName: normalizedReferenceName,
      expensivePrice: referencePrice,
      expensiveImageUrl: '',
      alternativeName: normalizedComparisonName,
      alternativePrice: comparisonPrice,
      alternativeImageUrl: '',
      buyUrl: normalizedUrl.isEmpty
          ? ''
          : AffiliateLinkService.attachAffiliateTag(normalizedUrl),
      rating: 0,
      reviewCount: 0,
      tags: [
        normalizedCategory,
        normalizedReferenceName,
        normalizedComparisonName,
        'admin-entry',
      ],
    );
  }
}
