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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF8F1), Color(0xFFFFE7D1)],
        ),
        border: Border.all(color: AppPalette.dealsBorder),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  resolveStoreLogoUrl(
                    storeId: coupon.storeId,
                    productUrl: '',
                    fallbackName: coupon.storeName,
                  ),
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.storefront_rounded,
                    color: AppPalette.navy,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  coupon.title ??
                      tr(
                        'كوبون حصري من ${coupon.storeName}',
                        'Exclusive coupon from ${coupon.storeName}',
                      ),
                  style: TextStyle(
                    color: AppPalette.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            coupon.discountLabel,
            style: TextStyle(
              color: AppPalette.orange,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coupon.description ??
                tr(
                  'انسخ الكود واستخدمه عند إتمام الطلب.',
                  'Copy the code and use it at checkout.',
                ),
            style: TextStyle(
              color: AppPalette.softNavy,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => onCopyCoupon(coupon.code),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppPalette.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppPalette.comparisonBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: TextStyle(
                        color: AppPalette.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Icon(Icons.copy_rounded, color: AppPalette.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expiryLabel,
            style: TextStyle(
              color: AppPalette.softNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
