import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'home_exports.dart';

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({
    super.key,
    required this.comparison,
    required this.onBuyTap,
    required this.onShareTap,
    required this.onRateTap,
    this.onLocationTap,
  });

  final ProductComparison comparison;
  final VoidCallback? onBuyTap;
  final VoidCallback onShareTap;
  final VoidCallback onRateTap;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110C3B2E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.comparisonSoftEmerald,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    localizedCategoryLabelForId(
                      comparison.categoryId,
                      fallbackLabel: comparison.categoryLabel,
                    ),
                    style: const TextStyle(
                      color: AppPalette.comparisonEmerald,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (comparison.isAutomated) ...[
                  const SizedBox(width: 8),
                  const AutomatedComparisonBadge(),
                ],
                if (comparison.isSuperSaving) ...[
                  const SizedBox(width: 8),
                  const SuperSavingBadge(),
                ],
                if (comparison.hasOriginalOfferTag) ...[
                  const SizedBox(width: 8),
                  const OriginalOnSaleBadge(),
                ],
                const Spacer(),
                SavingBadge(savingsPercent: comparison.savingsPercent),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                if (isCompact) {
                  return Column(
                    children: [
                      ProductPane(
                        label: tr('الخيار الأعلى سعراً',
                            'Higher-priced option'),
                        name: comparison.expensiveName,
                        price: comparison.expensivePrice,
                        imageUrl: comparison.expensiveImageUrl,
                        highlighted: false,
                        icon: Icons.trending_up_rounded,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: Color(0xFFE8711A),
                          size: 28,
                        ),
                      ),
                      ProductPane(
                        label: tr('الخيار الأفضل قيمة',
                            'Best value option'),
                        name: comparison.alternativeName,
                        price: comparison.alternativePrice,
                        imageUrl: comparison.alternativeImageUrl,
                        highlighted: true,
                        icon: Icons.check_circle_rounded,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: ProductPane(
                        label: tr('الخيار الأعلى سعراً',
                            'Higher-priced option'),
                        name: comparison.expensiveName,
                        price: comparison.expensivePrice,
                        imageUrl: comparison.expensiveImageUrl,
                        highlighted: false,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Color(0xFFE8711A),
                        size: 30,
                      ),
                    ),
                    Expanded(
                      child: ProductPane(
                        label: tr('الخيار الأفضل قيمة',
                            'Best value option'),
                        name: comparison.alternativeName,
                        price: comparison.alternativePrice,
                        imageUrl: comparison.alternativeImageUrl,
                        highlighted: true,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFFE8711A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      comparison.hasOriginalOfferTag
                          ? tr(
                              'المنتج الأصلي أصبح الأرخص حالياً، لذلك ننصح بمراجعة العرض قبل الشراء.',
                              'The original product is currently cheaper, so we recommend checking this offer before buying.',
                            )
                          : tr(
                              'فرق السعر: ${formatPrice(comparison.savingsAmount)} لصالح الخيار الأفضل قيمة.',
                              'Price difference: ${formatPrice(comparison.savingsAmount)} in favor of the best value option.',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF224238),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (comparison.isAutomated) ...[
                    const SizedBox(width: 10),
                    const AutomatedComparisonBadge(compact: true),
                  ],
                ],
              ),
            ),
            if (comparison.hasDetailHighlights ||
                comparison.hasLocationLink) ...[
              const SizedBox(height: 14),
              ComparisonInsights(
                comparison: comparison,
                onLocationTap: onLocationTap,
              ),
            ],
            const SizedBox(height: 14),
            RatingSummary(
              comparison: comparison,
              onTap: onRateTap,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 430;

                if (isNarrow) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onShareTap,
                          icon: const Icon(Icons.share_rounded),
                          label: Text(tr(
                              'مشاركة التوفير', 'Share savings')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onBuyTap,
                          icon: const Icon(Icons.chat_rounded),
                          label: Text(
                            comparison.hasBuyUrl
                                ? tr('فتح واتساب', 'Open WhatsApp')
                                : tr('بدون واتساب', 'No WhatsApp'),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShareTap,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(
                            tr('مشاركة التوفير', 'Share savings')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyTap,
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(
                          comparison.hasBuyUrl
                              ? tr('فتح واتساب', 'Open WhatsApp')
                              : tr('بدون واتساب', 'No WhatsApp'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
