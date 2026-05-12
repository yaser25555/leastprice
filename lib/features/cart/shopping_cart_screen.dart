import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';
import 'package:leastprice/data/models/cart_item.dart';
import 'package:leastprice/features/home/comparison_image_fallback.dart';

class ShoppingCartScreen extends ConsumerWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(shoppingCartProvider);
    final notifier = ref.read(shoppingCartProvider.notifier);
    final totalPrice = notifier.totalPrice;
    final storeSummary = notifier.storeSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('سلة التوفير', 'Savings Cart'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPalette.deepNavy,
        foregroundColor: AppPalette.orange,
        actions: [
          if (cartItems.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: notifier.shareText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('تم نسخ السلة، يمكنك مشاركتها الآن',
                        'Cart copied, you can share it now')),
                    backgroundColor: AppPalette.comparisonEmerald,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: tr('مشاركة', 'Share'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => notifier.clearCart(),
              tooltip: tr('إفراغ السلة', 'Clear Cart'),
            ),
          ],
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_rounded,
                      size: 80, color: AppPalette.softNavy),
                  const SizedBox(height: 16),
                  Text(
                    tr('السلة فارغة حالياً', 'Cart is currently empty'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.deepNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('ابحث عن المنتجات وأضفها للسلة لمقارنة إجمالي التكلفة',
                        'Search for products and add them to compare total cost'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPalette.mutedText),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _SummaryHeader(
                  totalPrice: totalPrice,
                  storeSummary: storeSummary,
                  itemCount: cartItems.fold(0, (s, e) => s + e.quantity),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onIncrement: () =>
                            notifier.incrementQuantity(item.product.productUrl),
                        onDecrement: () =>
                            notifier.decrementQuantity(item.product.productUrl),
                        onRemove: () =>
                            notifier.removeItem(item.product.productUrl),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalPrice,
    required this.storeSummary,
    required this.itemCount,
  });

  final double totalPrice;
  final Map<String, ({double total, int count})> storeSummary;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 4),
          Text(
            '$itemCount ${tr('قطعة', 'item(s)')}',
            style: TextStyle(color: AppPalette.paleOrange.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (storeSummary.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('نصيحة: لقد جمعت منتجات من متاجر مختلفة. التسوق من متجر واحد قد يوفر رسوم التوصيل.',
                          'Tip: You collected items from different stores. Shopping from one store might save delivery fees.'),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Store Summary Cards
          ...storeSummary.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded,
                        size: 18, color: AppPalette.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppPalette.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value.count}x • ${formatAmountValue(entry.value.total)} SAR',
                        style: TextStyle(
                          color: AppPalette.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    proxiedImageUrl(product.imageUrl),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ComparisonImageFallback(),
                  )
                : const ComparisonImageFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
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
                    Icon(Icons.storefront_rounded,
                        size: 14, color: AppPalette.mutedText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.storeName,
                        style:
                            TextStyle(color: AppPalette.mutedText, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Quantity controls
                    _QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: item.quantity > 1 ? onDecrement : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppPalette.deepNavy,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrement,
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
                '${formatAmountValue(item.totalPrice)} SAR',
                style: TextStyle(
                  color: AppPalette.comparisonEmerald,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (item.quantity > 1)
                Text(
                  '${formatAmountValue(product.price)} ${tr('للقطعة', 'each')}',
                  style: TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 11,
                  ),
                ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.redAccent, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(top: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppPalette.softOrange.withValues(alpha: 0.3)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppPalette.orange : Colors.grey.shade300,
        ),
      ),
    );
  }
}
