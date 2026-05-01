import 'dart:async';

import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

import 'comparison_search_placeholder.dart';
import 'exclusive_coupon_card.dart';

class CouponsListSection extends StatefulWidget {
  const CouponsListSection({
    super.key,
    required this.stream,
    required this.onCopyCoupon,
  });

  final Stream<List<Coupon>> stream;
  final ValueChanged<String> onCopyCoupon;

  @override
  State<CouponsListSection> createState() => _CouponsListSectionState();
}

class _CouponsListSectionState extends State<CouponsListSection> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: StreamBuilder<List<Coupon>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppPalette.orange),
              ),
            );
          }

          if (snapshot.hasError) {
            return ComparisonSearchPlaceholder(
              title: tr(
                'تعذر تحميل الكوبونات حالياً.',
                'Unable to load coupons right now.',
              ),
              icon: Icons.discount_outlined,
            );
          }

          final coupons = (snapshot.data ?? const <Coupon>[])
              .where(
                (coupon) =>
                    coupon.active &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.code.trim().isNotEmpty,
              )
              .toList();

          if (coupons.isEmpty) {
            return ComparisonSearchPlaceholder(
              title: tr(
                'لا توجد كوبونات نشطة حالياً. سنضيف المزيد قريبًا.',
                'No active coupons right now. More are coming soon.',
              ),
              icon: Icons.local_offer_outlined,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppPalette.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(
                        'كوبوناتك الحصرية (${coupons.length})',
                        'Your exclusive coupons (${coupons.length})',
                      ),
                      style: TextStyle(
                        color: AppPalette.panelText,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'انسخ الكود قبل إتمام الطلب لتحصل على وفر إضافي.',
                  'Copy the code before checkout to unlock extra savings.',
                ),
                style: TextStyle(
                  color: AppPalette.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return ExclusiveCouponCard(
                    coupon: coupon,
                    now: _now,
                    onCopyCoupon: widget.onCopyCoupon,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
