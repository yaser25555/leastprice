import 'dart:async';

import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

import 'home_exports.dart';

class ExclusiveCouponsSection extends StatefulWidget {
  const ExclusiveCouponsSection({
    super.key,
    required this.stream,
    required this.onCopyCoupon,
  });

  final Stream<List<Coupon>> stream;
  final ValueChanged<String> onCopyCoupon;

  @override
  State<ExclusiveCouponsSection> createState() =>
      _ExclusiveCouponsSectionState();
}

class _ExclusiveCouponsSectionState extends State<ExclusiveCouponsSection> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: StreamBuilder<List<Coupon>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
            return const SizedBox.shrink();
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
                    coupon.isSupportedFeaturedStore &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.active,
              )
              .toList();
          if (coupons.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  'كوبونات حصرية لأهل الشرقية',
                  'Exclusive coupons for Eastern Region families',
                ),
                style: TextStyle(
                  color: AppPalette.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'انسخ الكود المناسب قبل إتمام الطلب لتحصل على وفر إضافي.',
                  'Copy the right code before checkout to unlock extra savings.',
                ),
                style: TextStyle(
                  color: AppPalette.softNavy,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: coupons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return SizedBox(
                      width: 320,
                      child: ExclusiveCouponCard(
                        coupon: coupon,
                        now: _now,
                        onCopyCoupon: widget.onCopyCoupon,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
