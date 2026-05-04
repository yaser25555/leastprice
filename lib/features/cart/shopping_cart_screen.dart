import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';
import 'package:leastprice/features/home/comparison_image_fallback.dart';
import 'package:url_launcher/url_launcher.dart';

class ShoppingCartScreen extends ConsumerWidget {
  const ShoppingCartScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(shoppingCartProvider);
    final totalPrice = ref.read(shoppingCartProvider.notifier).totalPrice;

    // Group items by store to show potential savings
    final Map<String, double> storeTotals = {};
    for (var item in cartItems) {
      storeTotals[item.storeName] = (storeTotals[item.storeName] ?? 0) + item.price;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('سلة التوفير', 'Savings Cart'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.deepNavy,
        foregroundColor: AppPalette.orange,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                ref.read(shoppingCartProvider.notifier).clearCart();
              },
              tooltip: tr('إفراغ السلة', 'Clear Cart'),
            )
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_rounded, size: 80, color: AppPalette.softNavy),
                  const SizedBox(height: 16),
                  Text(
                    tr('السلة فارغة حالياً', 'Cart is currently empty'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.deepNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('ابحث عن المنتجات وأضفها للسلة لمقارنة إجمالي التكلفة', 'Search for products and add them to compare total cost'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPalette.mutedText),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppPalette.deepNavy,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tr('التكلفة الإجمالية لطلباتك', 'Total Cost of your items'),
                        style: TextStyle(color: AppPalette.paleOrange, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatAmountValue(totalPrice)} SAR',
                        style: TextStyle(
                          color: AppPalette.orange,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (storeTotals.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr('نصيحة: لقد جمعت منتجات من متاجر مختلفة. التسوق من متجر واحد قد يوفر رسوم التوصيل.', 'Tip: You collected items from different stores. Shopping from one store might save delivery fees.'),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                
                // Cart Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.deepNavy.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ComparisonImageFallback(),
                                    )
                                  : const ComparisonImageFallback(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppPalette.deepNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 14, color: AppPalette.mutedText),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.storeName,
                                        style: TextStyle(color: AppPalette.mutedText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${formatAmountValue(item.price)} SAR',
                                  style: TextStyle(
                                    color: AppPalette.comparisonEmerald,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    ref.read(shoppingCartProvider.notifier).removeItem(item.productUrl);
                                  },
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(top: 8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
