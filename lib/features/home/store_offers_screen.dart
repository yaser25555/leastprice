import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreOffersScreen extends ConsumerWidget {
  const StoreOffersScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.storeNameEn,
    required this.storeColor,
    required this.storeLogoUrl,
  });

  final String storeId;
  final String storeName;
  final String storeNameEn;
  final Color storeColor;
  final String? storeLogoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: productsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    tr('فشل تحميل المنتجات', 'Failed to load products'),
                    style: TextStyle(color: AppPalette.navy),
                  ),
                ),
              ),
              data: (products) => _buildProductSlivers(context, products),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final hasLogo = storeLogoUrl != null && storeLogoUrl!.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                storeColor,
                storeColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasLogo)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          proxiedImageUrl(storeLogoUrl!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildLetterBadge(),
                        ),
                      )
                    else
                      _buildLetterBadge(),
                    const SizedBox(height: 12),
                    Text(
                      tr(storeName, storeNameEn),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('عروض وبدائل أقل سعراً', 'Offers & cheaper alternatives'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterBadge() {
    final char = storeName.isNotEmpty ? storeName.characters.first : '?';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildProductSlivers(
    BuildContext context,
    List<ProductComparison> allProducts,
  ) {
    final storeProducts = allProducts.where((p) {
      final inferred = inferStoreIdFromUrl(p.buyUrl);
      return inferred == storeId;
    }).toList();

    if (storeProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.store_rounded, size: 64, color: storeColor.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                tr('لا توجد عروض متاحة حالياً', 'No offers available yet'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.navy.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = storeProducts[index];
          return _buildProductCard(context, product);
        },
        childCount: storeProducts.length,
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductComparison product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: storeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category label ──
          if (product.categoryLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.folder_rounded, size: 14, color: storeColor),
                  const SizedBox(width: 6),
                  Text(
                    product.categoryLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: storeColor,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Expensive product ──
                Expanded(
                  child: _buildProductSide(
                    name: product.expensiveName,
                    price: product.expensivePrice,
                    imageUrl: product.expensiveImageUrl,
                    isExpensive: true,
                  ),
                ),
                // ── VS divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: storeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            tr('vs', 'vs'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: storeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Alternative product ──
                Expanded(
                  child: _buildProductSide(
                    name: product.alternativeName,
                    price: product.alternativePrice,
                    imageUrl: product.alternativeImageUrl,
                    isExpensive: false,
                  ),
                ),
              ],
            ),
          ),
          // ── Buy button ──
          if (product.hasBuyUrl)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openBuyUrl(context, product.buyUrl),
                  icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                  label: Text(
                    tr('اشتري من $storeName', 'Buy at $storeNameEn'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: storeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSide({
    required String name,
    required double price,
    required String imageUrl,
    required bool isExpensive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            proxiedImageUrl(imageUrl),
            width: double.infinity,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              decoration: BoxDecoration(
                color: storeColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  color: storeColor.withValues(alpha: 0.3),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)} ${tr('ريال', 'SAR')}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isExpensive ? AppPalette.navy : AppPalette.orange,
          ),
        ),
        if (isExpensive)
          Text(
            tr('السعر المرجعي', 'Reference price'),
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.navy.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        if (!isExpensive)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppPalette.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tr('أقل سعر', 'Best price'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppPalette.orange,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openBuyUrl(BuildContext context, String url) async {
    final prepared = AffiliateLinkService.prepareForOpen(url);
    final uri = Uri.parse(prepared);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final allProductsStreamProvider = StreamProvider<List<ProductComparison>>((ref) {
  return const FirestoreCatalogService().watchAllProducts();
});
