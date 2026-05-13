import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/features/home/grouped_product_card.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';
import 'package:leastprice/features/home/home_data_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leastprice/features/home/widgets/price_alert_button.dart';

class GroupedComparisonCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final bestPrice = group.lowestPrice;
    final bestStore = group.offers.first;
    final currentUser = FirebaseAuth.instance.currentUser;
    UserSavingsProfile? userProfile;
    if (currentUser != null) {
      userProfile = ref.watch(userProfileStreamProvider(currentUser.uid)).value;
    }
    final isPaid = userProfile?.planActivated ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppPalette.brandCardBorder),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 100,
                        width: 100,
                        color: AppPalette.brandSurface,
                        child: Image.network(
                          proxiedImageUrl(group.displayImageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.image_outlined,
                              size: 32, color: AppPalette.brandCardBorder),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CartShortcut(offer: bestStore),
                          const SizedBox(width: 4),
                          _FavoriteShortcut(group: group),
                          const SizedBox(width: 4),
                          PriceAlertButton(
                            productTitle: group.displayTitle,
                            productUrl: bestStore.productUrl,
                            imageUrl: group.displayImageUrl,
                            storeId: bestStore.storeId,
                            storeName: bestStore.storeName,
                            currentPrice: bestPrice,
                            isPaid: isPaid,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppPalette.comparisonEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tr('أقل سعر', 'Best price')}: ${formatAmountValue(bestPrice)} ${bestStore.currency}',
                          style: TextStyle(
                            color: AppPalette.comparisonEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (group.offers.length > 1)
                            Text(
                              '${group.offers.length} ${tr('متجر', 'stores')}',
                              style: TextStyle(
                                color: isFeminineTheme.value
                                    ? Colors.grey.shade400
                                    : Colors.white38,
                                fontSize: 10,
                              ),
                            )
                          else
                            const SizedBox(),
                          Consumer(
                            builder: (context, ref, child) {
                              final notifier = ref.read(shoppingCartProvider.notifier);
                              final qty = notifier.quantityOf(bestStore.productUrl);
                              final inCart = qty > 0;
                              return InkWell(
                                onTap: inCart
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
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: inCart
                                        ? null
                                        : AppPalette.gradientWarmCta,
                                    color: inCart
                                        ? AppPalette.comparisonEmerald.withValues(alpha: 0.15)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: inCart
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AppPalette.orange
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        inCart
                                            ? Icons.check_circle
                                            : Icons.add_shopping_cart_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        inCart
                                            ? tr('بالسلة', 'In Cart')
                                            : tr('أضف للسلة', 'Add'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (group.offers.length > 1) ...[
            Divider(height: 1, color: AppPalette.brandCardBorder),
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

class _FavoriteShortcut extends ConsumerWidget {
  final GroupedProductCard group;
  const _FavoriteShortcut({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesStreamProvider);
    final offer = group.offers.first;
    
    return favoritesAsync.when(
      data: (favorites) {
        final isFavorite = favorites.any((f) => f['productUrl'] == offer.productUrl);
        return _ShortcutCircle(
          icon: isFavorite ? Icons.favorite : Icons.favorite_outline,
          color: isFavorite ? AppPalette.orange : Colors.grey.shade600,
          onTap: () => _toggleFavorite(context, ref, isFavorite),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, bool isFavorite) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('سجل دخول لحفظ المنتجات', 'Login to save favorites'))),
        );
        return;
      }

      final catalog = ref.read(firestoreCatalogProvider);
      final offer = group.offers.first;

      if (isFavorite) {
        await catalog.removeFavorite(offer.productUrl);
      } else {
        await catalog.addFavorite(
          productTitle: group.displayTitle,
          productUrl: offer.productUrl,
          price: group.lowestPrice,
          currency: offer.currency,
          storeName: offer.storeName,
          storeId: offer.storeId,
          imageUrl: group.displayImageUrl,
        );
      }
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('حدث خطأ، حاول مرة أخرى', 'Error, try again'))),
      );
    }
  }
}

class _CartShortcut extends ConsumerWidget {
  final ComparisonSearchResult offer;
  const _CartShortcut({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(shoppingCartProvider.notifier);
    final qty = ref.watch(shoppingCartProvider.select((cart) => 
      notifier.quantityOf(offer.productUrl)));
    final inCart = qty > 0;

    return _ShortcutCircle(
      icon: inCart ? Icons.check_circle : Icons.add_shopping_cart_rounded,
      color: inCart ? AppPalette.comparisonEmerald : AppPalette.orange,
      onTap: inCart ? null : () {
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
    );
  }
}

class _ShortcutCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ShortcutCircle({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 14, color: color),
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
                      color: AppPalette.brandSurface,
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
                                  : (isFeminineTheme.value
                                      ? Colors.black87
                                      : Colors.white70),
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
                            : (isFeminineTheme.value
                                ? Colors.black54
                                : Colors.white54),
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
                      color: inCart
                          ? AppPalette.comparisonEmerald
                          : (isFeminineTheme.value
                              ? AppPalette.navy.withValues(alpha: 0.6)
                              : Colors.white60),
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
          Divider(indent: 60, height: 1, color: AppPalette.brandCardBorder),
      ],
    );
  }
}
