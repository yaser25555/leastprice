import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/features/home/comparison_image_fallback.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_exports.dart';

class ComparisonSearchResultCard extends StatelessWidget {
  const ComparisonSearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.onCopyCoupon,
  });

  final ComparisonSearchResult result;
  final VoidCallback onTap;
  final VoidCallback? onCopyCoupon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppPalette.cardBackground,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppPalette.premium3DBoxShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: result.imageUrl.trim().isNotEmpty
                  ? Image.network(
                      result.imageUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ComparisonImageFallback(),
                    )
                  : const ComparisonImageFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.comparisonSoftEmerald,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr('محدث آلياً', 'Updated automatically'),
                          style: TextStyle(
                            color: AppPalette.comparisonEmerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.2,
                          ),
                        ),
                      ),
                      if (result.isPreferredMarketplace)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5CF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tr('أولوية نون/أمازون', 'Noon/Amazon priority'),
                            style: TextStyle(
                              color: AppPalette.panelText,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.2,
                            ),
                          ),
                        ),
                      if (result.tag != null && result.tag!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.softOrange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            result.tag!,
                            style: TextStyle(
                              color: AppPalette.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const AppBrandMark(
                        size: 26,
                        padding: 4,
                        borderRadius: 9,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LeastPrice • ${result.channelType.label}',
                          style: TextStyle(
                            color: AppPalette.mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.title,
                    style: TextStyle(
                      color: AppPalette.panelText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatAmountValue(result.price)} ${result.currency}',
                    style: TextStyle(
                      color: AppPalette.comparisonEmerald,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (result.matchedCoupon != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: onCopyCoupon != null ? () {
                        HapticFeedback.selectionClick();
                        onCopyCoupon!();
                      } : null,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.comparisonSoftEmerald,
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: AppPalette.comparisonBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              color: AppPalette.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('وفر أكثر!', 'Save more!'),
                                    style: TextStyle(
                                      color: AppPalette.panelText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr(
                                      'استخدم كود الخصم: ${result.matchedCoupon!.code}',
                                      'Use coupon code: ${result.matchedCoupon!.code}',
                                    ),
                                    style: TextStyle(
                                      color: AppPalette.mutedText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy_rounded,
                              color: AppPalette.softTurquoise,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (result.storeLogoUrl.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.network(
                            result.storeLogoUrl,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: AppPalette.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          result.storeName,
                          style: TextStyle(
                            color: AppPalette.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final cartItems = ref.watch(shoppingCartProvider);
                      final isInCart = cartItems.any((item) => item.productUrl == result.productUrl);

                      return Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppPalette.comparisonEmerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 20),
                              label: Text(tr('فتح المتجر', 'Open store')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (isInCart) {
                                ref.read(shoppingCartProvider.notifier).removeItem(result.productUrl);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('تمت إزالة المنتج من السلة', 'Item removed from cart')),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } else {
                                ref.read(shoppingCartProvider.notifier).addItem(result);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('تمت إضافة المنتج للسلة', 'Item added to cart')),
                                    backgroundColor: AppPalette.comparisonEmerald,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isInCart ? AppPalette.softOrange : AppPalette.paleOrange.withOpacity(0.2),
                              foregroundColor: isInCart ? AppPalette.orange : AppPalette.deepNavy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: Icon(isInCart ? Icons.shopping_cart_rounded : Icons.add_shopping_cart_rounded, size: 20),
                            label: Text(isInCart ? tr('مضاف للسلة', 'In Cart') : tr('أضف للسلة', 'Add to Cart')),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
