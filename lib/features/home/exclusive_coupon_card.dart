import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

class ExclusiveCouponCard extends StatelessWidget {
  const ExclusiveCouponCard({
    super.key,
    required this.coupon,
    required this.now,
    required this.onCopyCoupon,
  });

  final Coupon coupon;
  final DateTime now;
  final ValueChanged<String> onCopyCoupon;

  @override
  Widget build(BuildContext context) {
    final remaining = coupon.expiresAt.difference(now);
    final remainingDays = remaining.inDays;
    final logoUrl = (coupon.storeLogoUrl ?? '').trim().isNotEmpty
        ? coupon.storeLogoUrl!.trim()
        : resolveStoreLogoUrl(
            storeId: coupon.storeId,
            productUrl: coupon.storeUrl ?? '',
            fallbackName: coupon.storeName,
          );
    final expiryLabel = remaining.inHours >= 24
        ? tr(
            'ينتهي خلال ${remainingDays + 1} يوم',
            'Ends in ${remainingDays + 1} day(s)',
          )
        : tr(
            'ينتهي خلال ${remaining.inHours.clamp(0, 23)} ساعة',
            'Ends in ${remaining.inHours.clamp(0, 23)} hour(s)',
          );

    return Container(
      padding: const EdgeInsets.all(1), // Border width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.orange.withValues(alpha: 0.15),
            AppPalette.orange.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPalette.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      proxiedImageUrl(logoUrl),
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.storefront_rounded,
                        color: AppPalette.orange,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.storeName,
                        style: TextStyle(
                          color: AppPalette.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        coupon.title ?? tr('كوبون حصري', 'Exclusive coupon'),
                        style: TextStyle(
                          color: AppPalette.brandNavyDeep,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tr('موثوق', 'Verified'),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppPalette.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppPalette.orange.withValues(alpha: 0.2),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        coupon.discountLabel,
                        style: TextStyle(
                          color: AppPalette.orange,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('خصم إضافي عند الدفع', 'Extra discount at checkout'),
                        style: TextStyle(
                          color: AppPalette.softNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              coupon.description ?? tr('انسخ الكود للحصول على الخصم.', 'Copy the code to get the discount.'),
              style: TextStyle(
                color: AppPalette.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Code Copy Section with "Scissor/Coupon" look
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onCopyCoupon(coupon.code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('تم نسخ الكود بنجاح!', 'Code copied successfully!')),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppPalette.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppPalette.brandNavyDeep,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.brandNavyDeep.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          coupon.code,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: remainingDays <= 2 ? Colors.red : AppPalette.softNavy, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      expiryLabel,
                      style: TextStyle(
                        color: remainingDays <= 2 ? Colors.red : AppPalette.softNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  tr('تطبق الشروط', 'T&C Apply'),
                  style: TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
