import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/home_data_providers.dart';

class PriceAlertButton extends ConsumerWidget {
  const PriceAlertButton({
    super.key,
    required this.productTitle,
    required this.productUrl,
    required this.imageUrl,
    required this.storeId,
    required this.storeName,
    required this.currentPrice,
    this.isPaid = false,
  });

  final String productTitle;
  final String productUrl;
  final String imageUrl;
  final String storeId;
  final String storeName;
  final double currentPrice;
  final bool isPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.read(firestoreCatalogProvider);

    return FutureBuilder<Object?>(
      future: catalog.hasPriceAlert(productUrl),
      builder: (context, snap) {
        final hasAlert = snap.data != null;
        return _ShortcutCircle(
          icon: hasAlert ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          color: hasAlert ? AppPalette.orange : Colors.grey.shade600,
          onTap: () => _onTap(context, ref, hasAlert),
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, bool hasAlert) async {
    if (hasAlert) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr('إلغاء التنبيه', 'Remove alert')),
          content: Text(tr('هل تريد إلغاء تنبيه السعر لهذا المنتج؟', 'Remove price alert for this product?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('إلغاء', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('حذف', 'Delete')),
            ),
          ],
        ),
      );
      if (remove == true) {
        await ref.read(firestoreCatalogProvider).removePriceAlert(productUrl);
        if (context.mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('تم إلغاء التنبيه', 'Alert removed'))),
          );
        }
      }
      return;
    }

    if (!isPaid) {
      _showPaywall(context);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('سجل دخول أولاً', 'Login first'))),
      );
      return;
    }

    final targetPrice = await showDialog<double>(
      context: context,
      builder: (_) => _SetPriceAlertDialog(currentPrice: currentPrice),
    );
    if (targetPrice == null || !context.mounted) return;

    await ref.read(firestoreCatalogProvider).setPriceAlert(
      productTitle: productTitle,
      productUrl: productUrl,
      imageUrl: imageUrl,
      storeId: storeId,
      storeName: storeName,
      targetPrice: targetPrice,
    );
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('تم تعيين تنبيه السعر', 'Price alert set')),
        backgroundColor: AppPalette.comparisonEmerald,
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: AppPalette.orange),
            const SizedBox(width: 8),
            Text(tr('ميزة مدفوعة', 'Premium feature')),
          ],
        ),
        content: Text(tr(
          'تنبيهات السعر متاحة للمشتركين فقط. اشترك الآن لتفعيلها.',
          'Price alerts are only available for paid subscribers. Subscribe now to enable them.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('رجوع', 'Back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to plans section
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('اشترك الآن', 'Subscribe now')),
          ),
        ],
      ),
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

class _SetPriceAlertDialog extends StatefulWidget {
  final double currentPrice;
  const _SetPriceAlertDialog({required this.currentPrice});

  @override
  State<_SetPriceAlertDialog> createState() => _SetPriceAlertDialogState();
}

class _SetPriceAlertDialogState extends State<_SetPriceAlertDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentPrice * 0.8).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(tr('تنبيه السعر', 'Price Alert')),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr('السعر الحالي', 'Current price')}: SAR ${widget.currentPrice.toStringAsFixed(0)}',
                style: TextStyle(color: AppPalette.mutedText),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('السعر المستهدف', 'Target price'),
                  prefixText: 'SAR ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return tr('أدخل سعراً صحيحاً', 'Enter a valid price');
                  }
                  if (parsed >= widget.currentPrice) {
                    return tr(
                      'يجب أن يكون أقل من السعر الحالي',
                      'Must be lower than current price',
                    );
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('إلغاء', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, double.parse(_controller.text.trim()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('تعيين', 'Set')),
          ),
        ],
      ),
    );
  }
}
