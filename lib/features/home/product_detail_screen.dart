import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/features/home/grouped_product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.group,
    required this.onOpenStore,
  });

  final GroupedProductCard group;
  final void Function(String url) onOpenStore;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = const FirestoreCatalogService();
  bool _isFavorite = false;
  bool _favLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  void _checkFavorite() async {
    try {
      final fav = await _service.isFavorite(widget.group.offers.first.productUrl);
      if (mounted) setState(() { _isFavorite = fav; _favLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('سجل دخول لحفظ المنتجات', 'Login to save favorites'))),
          );
        }
        return;
      }

      final offer = widget.group.offers.first;
      if (_isFavorite) {
        await _service.removeFavorite(offer.productUrl);
      } else {
        await _service.addFavorite(
          productTitle: widget.group.displayTitle,
          productUrl: offer.productUrl,
          price: widget.group.lowestPrice,
          currency: offer.currency,
          storeName: offer.storeName,
          storeId: offer.storeId,
          imageUrl: widget.group.displayImageUrl,
        );
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('حدث خطأ، حاول مرة أخرى', 'Error, try again'))),
        );
      }
    }
  }

  GroupedProductCard get group => widget.group;
  void Function(String url) get _onOpenStore => widget.onOpenStore;

  @override
  Widget build(BuildContext context) {
    final bestPrice = group.lowestPrice;

    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      appBar: AppBar(
        backgroundColor: AppPalette.cardBackground,
        surfaceTintColor: AppPalette.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _favLoading
                  ? Icons.favorite_outline
                  : _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_outline,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            onPressed: _favLoading ? null : _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareProduct(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey.shade50,
              child: Image.network(
                group.displayImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: AppPalette.comparisonEmerald,
                      ),
                    ),
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      group.displayTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            group.displayTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.comparisonEmerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'أقل سعر: ${formatAmountValue(bestPrice)} ${group.currency}',
              style: TextStyle(
                color: AppPalette.comparisonEmerald,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('العروض', 'Offers'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...group.offers.asMap().entries.map((entry) {
            final offer = entry.value;
            final isCheapest = offer.price == bestPrice;

            return _OfferCard(
              offer: offer,
              isCheapest: isCheapest,
              onTap: () => _onOpenStore(offer.productUrl),
            );
          }),
          if (group.matchedCoupon != null) ...[
            const SizedBox(height: 24),
            Text(
              tr('كود الخصم', 'Coupon'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _CouponCard(coupon: group.matchedCoupon!),
          ],
        ],
      ),
    );
  }

  void _shareProduct(BuildContext context) {
    final urls = group.offers.map((o) => o.productUrl).where((u) => u.isNotEmpty).toList();
    final text = group.matchedCoupon != null
        ? '${group.displayTitle}\n${tr('أقل سعر', 'Best price')}: ${formatAmountValue(group.lowestPrice)} ${group.currency}\n${group.matchedCoupon!.discountLabel}\n${tr('تسوق الآن', 'Shop now')}\n${urls.isNotEmpty ? urls.first : ''}'
        : '${group.displayTitle}\n${tr('أقل سعر', 'Best price')}: ${formatAmountValue(group.lowestPrice)} ${group.currency}\n${tr('تسوق الآن', 'Shop now')}\n${urls.isNotEmpty ? urls.first : ''}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('تم النسخ', 'Copied')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isCheapest,
    required this.onTap,
  });

  final ComparisonSearchResult offer;
  final bool isCheapest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCheapest
              ? AppPalette.comparisonEmerald.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: isCheapest ? 1.5 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                offer.storeLogoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.store, size: 22, color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          offer.storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCheapest)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.comparisonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tr('الأقل', 'Best'),
                            style: TextStyle(
                              color: AppPalette.comparisonEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatAmountValue(offer.price)} ${offer.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCheapest
                          ? AppPalette.comparisonEmerald
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: isCheapest
                      ? AppPalette.comparisonEmerald
                      : AppPalette.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(tr('فتح', 'Open')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.comparisonEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.comparisonEmerald.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded,
              color: AppPalette.comparisonEmerald, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              coupon.discountLabel,
              style: TextStyle(
                color: AppPalette.comparisonEmerald,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: coupon.code));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('تم نسخ الكود', 'Code copied!')),
                  backgroundColor: AppPalette.comparisonEmerald,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(tr('نسخ', 'Copy')),
          ),
        ],
      ),
    );
  }
}
