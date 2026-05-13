import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/features/home/grouped_product_card.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';

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
                      proxiedImageUrl(group.displayImageUrl),
                      fit: BoxFit.contain,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                            const SizedBox(height: 4),
                            Text(
                              '${group.offers.length} ${tr('متجر', 'stores')}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final notifier = ref.read(shoppingCartProvider.notifier);
                        final qty = notifier.quantityOf(bestStore.productUrl);
                        final inCart = qty > 0;
                        return ElevatedButton.icon(
                          onPressed: inCart
                              ? null
                              : () {
                                  notifier.addItem(bestStore);
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('تمت الإضافة للسلة', 'Added to cart')),
                                      backgroundColor: AppPalette.comparisonEmerald,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inCart
                                ? AppPalette.comparisonEmerald.withValues(alpha: 0.1)
                                : AppPalette.orange,
                            foregroundColor: inCart
                                ? AppPalette.comparisonEmerald
                                : Colors.white,
                            elevation: inCart ? 0 : 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            inCart ? Icons.check_circle : Icons.add_shopping_cart,
                            size: 16,
                          ),
                          label: Text(
                            inCart ? tr('في السلة', 'In Cart') : tr('أضف للسلة', 'Add'),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (group.offers.length > 1) ...[
            Divider(height: 1, color: Colors.grey.shade100),
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
          ],
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
                  proxiedImageUrl(offer.storeLogoUrl),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
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
                        ),
                        if (isCheapest)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              tr('الأفضل', 'Best'),
                              style: TextStyle(
                                fontSize: 9,
                                color: AppPalette.comparisonEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${formatAmountValue(offer.price)} ${offer.currency}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCheapest
                            ? AppPalette.comparisonEmerald
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final notifier = ref.read(shoppingCartProvider.notifier);
                  final qty = notifier.quantityOf(offer.productUrl);
                  final inCart = qty > 0;
                  return IconButton(
                    onPressed: inCart
                        ? null
                        : () {
                            notifier.addItem(offer);
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('تمت الإضافة للسلة', 'Added to cart')),
                                backgroundColor: AppPalette.comparisonEmerald,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                    icon: Icon(
                      inCart ? Icons.check_circle : Icons.add_shopping_cart_outlined,
                      size: 18,
                      color: inCart ? AppPalette.comparisonEmerald : AppPalette.navy.withValues(alpha: 0.6),
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  );
                },
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: AppPalette.orange.withValues(alpha: 0.1),
                    foregroundColor: AppPalette.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tr('فتح', 'Open'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
