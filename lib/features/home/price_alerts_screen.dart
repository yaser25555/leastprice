import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/home_data_providers.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(priceAlertsStreamProvider);

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
        title: Text(tr('تنبيهات السعر', 'Price Alerts')),
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    tr('لا توجد تنبيهات', 'No price alerts'),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'أضف تنبيه سعر لأي منتج لمراقبة السعر',
                      'Add a price alert to any product to track prices',
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: AppPalette.brandCardBorder,
            ),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final triggered = alert.hasTriggered;

              return Dismissible(
                key: ValueKey(alert.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(firestoreCatalogProvider).removePriceAlert(alert.productUrl);
                  HapticFeedback.mediumImpact();
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: AppPalette.brandSurface,
                      child: Image.network(
                        proxiedImageUrl(alert.imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: AppPalette.brandCardBorder,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    alert.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          '${tr('المستهدف', 'Target')}: SAR ${formatAmountValue(alert.targetPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: triggered
                                ? AppPalette.comparisonEmerald
                                : Colors.grey.shade600,
                            fontWeight: triggered ? FontWeight.bold : null,
                          ),
                        ),
                        if (alert.currentPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${tr('الحالي', 'Current')}: SAR ${formatAmountValue(alert.currentPrice!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: triggered
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.comparisonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr('تم التفعيل', 'Triggered'),
                            style: TextStyle(
                              color: AppPalette.comparisonEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            ref.read(firestoreCatalogProvider)
                                .removePriceAlert(alert.productUrl);
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('تم إلغاء التنبيه', 'Alert removed')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => Center(
          child: Text(tr('حدث خطأ', 'An error occurred')),
        ),
      ),
    );
  }
}
