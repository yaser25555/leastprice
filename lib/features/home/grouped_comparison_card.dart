import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/features/home/grouped_product_card.dart';

class GroupedComparisonCard extends StatelessWidget {
  const GroupedComparisonCard({
    super.key,
    required this.group,
    required this.onTapStore,
    this.onCopyCoupon,
  });

  final GroupedProductCard group;
  final void Function(String url) onTapStore;
  final VoidCallback? onCopyCoupon;

  @override
  Widget build(BuildContext context) {
    final bestPrice = group.lowestPrice;
    final bestStore = group.offers.first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Image.network(
                      group.displayImageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPalette.comparisonEmerald,
                            ),
                          ),
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 4),
                          Text(
                            group.displayTitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        group.displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppPalette.comparisonEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tr('أقل سعر', 'Best price')}: ${formatAmountValue(bestPrice)} ${bestStore.currency}',
                        style: TextStyle(
                          color: AppPalette.comparisonEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (group.offers.length > 1) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${group.offers.length} ${tr('متجر', 'stores')}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...group.offers.asMap().entries.map((entry) {
            final index = entry.key;
            final offer = entry.value;
            final isCheapest = offer.price == bestPrice;

            return _StoreRow(
              offer: offer,
              isCheapest: isCheapest,
              onTap: () => onTapStore(offer.productUrl),
              showDivider: index < group.offers.length - 1,
              onCopyCoupon: offer.matchedCoupon != null ? onCopyCoupon : null,
            );
          }),
          if (group.matchedCoupon != null && onCopyCoupon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: InkWell(
                onTap: onCopyCoupon,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.comparisonEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppPalette.comparisonEmerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_rounded,
                          size: 16, color: AppPalette.comparisonEmerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.matchedCoupon!.discountLabel,
                          style: TextStyle(
                            color: AppPalette.comparisonEmerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        tr('نسخ الكود', 'Copy code'),
                        style: TextStyle(
                          color: AppPalette.comparisonEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (group.offers.length <= 1 ||
              (group.matchedCoupon == null && group.offers.length > 1))
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.offer,
    required this.isCheapest,
    required this.onTap,
    required this.showDivider,
    this.onCopyCoupon,
  });

  final ComparisonSearchResult offer;
  final bool isCheapest;
  final VoidCallback onTap;
  final bool showDivider;
  final VoidCallback? onCopyCoupon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  offer.storeLogoUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.store, size: 16, color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.storeName,
                      style: TextStyle(
                        fontWeight: isCheapest ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: isCheapest
                            ? AppPalette.comparisonEmerald
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCheapest)
                      Text(
                        tr('أقل سعر', 'Lowest price'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppPalette.comparisonEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${formatAmountValue(offer.price)} ${offer.currency}',
                style: TextStyle(
                  fontWeight: isCheapest ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: isCheapest
                      ? AppPalette.comparisonEmerald
                      : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppPalette.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(tr('فتح', 'Open')),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(indent: 60, height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}
