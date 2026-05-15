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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: StreamBuilder<List<Coupon>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          final coupons = (snapshot.data ?? const <Coupon>[])
              .where(
                (coupon) =>
                    coupon.active &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.code.trim().isNotEmpty,
              )
              .where((coupon) {
                if (_searchQuery.isEmpty) return true;
                final query = _searchQuery.toLowerCase();
                return coupon.storeName.toLowerCase().contains(query) ||
                    coupon.code.toLowerCase().contains(query) ||
                    (coupon.title?.toLowerCase().contains(query) ?? false);
              })
              .toList();

          final uniqueStores = _getUniqueStores(coupons);

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
                        '🔥 كوبونات حصرية محدثة - Build 53.2',
                        '🔥 Exclusive Updated Coupons - Build 53.2',
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
                  'اختر المتجر المفضل لديك للحصول على أفضل الخصومات.',
                  'Pick your favorite store to get the best discounts.',
                ),
                style: TextStyle(
                  color: AppPalette.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Store Logos Quick Access - ALWAYS VISIBLE
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: uniqueStores.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final store = uniqueStores[index];
                    final isAldawaa =
                        (store['nameEn'] ?? '').toString().toLowerCase() ==
                            'al-dawaa';

                    return Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isAldawaa
                                ? Colors.black.withValues(alpha: 0.05)
                                : AppPalette.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isAldawaa
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : AppPalette.orange.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: _buildStoreLogo(store),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(store['name'], store['nameEn']),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.brandNavyDeep,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: tr('ابحث عن متجر أو كود خصم...', 'Search for a store or code...'),
                  prefixIcon: Icon(Icons.search_rounded, color: AppPalette.orange),
                  filled: true,
                  fillColor: AppPalette.orange.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppPalette.orange.withValues(alpha: 0.4), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppPalette.navy.withValues(alpha: 0.1)),
              const SizedBox(height: 20),

              // Coupons List Logic
              if (snapshot.connectionState == ConnectionState.waiting &&
                  coupons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppPalette.orange),
                  ),
                )
              else if (coupons.isEmpty)
                ComparisonSearchPlaceholder(
                  title: tr(
                    'لا توجد كوبونات نشطة حالياً. سنضيف المزيد قريبًا.',
                    'No active coupons right now. More are coming soon.',
                  ),
                  icon: Icons.local_offer_outlined,
                )
              else
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
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Build v53.2',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppPalette.mutedText.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getUniqueStores(List<Coupon> coupons) {
    // Primary application stores (Major retailers)
    final List<Map<String, dynamic>> appStores = [
      {
        'name': 'نون',
        'nameEn': 'Noon',
        'logoUrl': 'https://icon.horse/icon/noon.com'
      },
      {
        'name': 'أمازون',
        'nameEn': 'Amazon',
        'logoUrl': 'https://icon.horse/icon/amazon.sa'
      },
      {
        'name': 'نمشي',
        'nameEn': 'Namshi',
        'logoUrl': 'https://icon.horse/icon/namshi.com'
      },
      {
        'name': 'سيـفورا',
        'nameEn': 'Sephora',
        'logoUrl': 'https://icon.horse/icon/sephora.com'
      },
    ];

    final Map<String, Map<String, dynamic>> seen = {};

    // 1. Add stores that currently have active coupons (Prioritize them)
    for (var c in coupons) {
      final name = c.storeName;
      if (!seen.containsKey(name)) {
        seen[name] = {
          'name': name,
          'nameEn': name,
          'logoUrl': (c.storeLogoUrl ?? '').trim().isNotEmpty
              ? c.storeLogoUrl!.trim()
              : resolveStoreLogoUrl(
                  storeId: c.storeId,
                  productUrl: c.storeUrl ?? '',
                  fallbackName: name,
                ),
        };
      }
    }

    // 2. Fill in with other major application stores
    for (var s in appStores) {
      if (!seen.containsKey(s['name'])) {
        seen[s['name']] = s;
      }
    }

    return seen.values.toList();
  }

  Widget _buildStoreLogo(Map<String, dynamic> store) {
    final logoUrl = store['logoUrl'] as String? ?? '';
    final name = store['name'] as String;
    final nameEn = (store['nameEn'] as String).toLowerCase();

    final isAldawaa = nameEn == 'al-dawaa';
    final isCarrefour = nameEn == 'carrefour';

    if (logoUrl.isNotEmpty && !isAldawaa && !isCarrefour) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildTextFallback(name, nameEn),
        ),
      );
    }

    return _buildTextFallback(name, nameEn);
  }

  Widget _buildTextFallback(String name, String nameEn) {
    final isCarrefour = nameEn == 'carrefour';
    final isAldawaa = nameEn == 'al-dawaa';

    final text = (isCarrefour || isAldawaa)
        ? name
        : (name.isNotEmpty ? name.characters.first : '?');

    Color textColor = AppPalette.orange;
    if (isCarrefour) textColor = const Color(0xFF003087);
    if (isAldawaa) textColor = Colors.black;

    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: (isCarrefour || isAldawaa) ? 11 : 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
