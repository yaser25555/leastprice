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
          final coupons = (snapshot.data ?? const <Coupon>[])
              .where(
                (coupon) =>
                    coupon.active &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.code.trim().isNotEmpty,
              )
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
                        'تصفح الكوبونات حسب المتجر',
                        'Browse coupons by store',
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
                    final isAldawaa = (store['nameEn'] ?? '').toString().toLowerCase() == 'al-dawaa';
                    
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
              Divider(height: 1, color: AppPalette.navy.withValues(alpha: 0.1)),
              const SizedBox(height: 20),

              // Coupons List Logic
              if (snapshot.connectionState == ConnectionState.waiting && coupons.isEmpty)
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
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getUniqueStores(List<Coupon> coupons) {
    // Primary application stores (Major retailers)
    final List<Map<String, dynamic>> appStores = [
      {'name': 'نون', 'nameEn': 'Noon', 'logoUrl': 'https://icon.horse/icon/noon.com'},
      {'name': 'أمازون', 'nameEn': 'Amazon', 'logoUrl': 'https://icon.horse/icon/amazon.sa'},
      {'name': 'نمشي', 'nameEn': 'Namshi', 'logoUrl': 'https://icon.horse/icon/namshi.com'},
      {'name': 'شي إن', 'nameEn': 'SHEIN', 'logoUrl': 'https://icon.horse/icon/shein.com'},
      {'name': 'آي هيرب', 'nameEn': 'iHerb', 'logoUrl': 'https://icon.horse/icon/iherb.com'},
      {'name': 'سيـفورا', 'nameEn': 'Sephora', 'logoUrl': 'https://icon.horse/icon/sephora.com'},
      {'name': 'جرير', 'nameEn': 'Jarir', 'logoUrl': 'https://icon.horse/icon/jarir.com'},
      {'name': 'إكسترا', 'nameEn': 'Extra', 'logoUrl': 'https://icon.horse/icon/extra.com'},
      {'name': 'بنده', 'nameEn': 'Panda', 'logoUrl': 'https://www.panda.sa/_next/static/media/logo.f85b0530.svg'},
      {'name': 'العثيم', 'nameEn': 'Othaim', 'logoUrl': 'https://icon.horse/icon/othaimmarkets.com'},
      {'name': 'التميمي', 'nameEn': 'Tamimi', 'logoUrl': 'https://www.tamimimarkets.com/__template/images/logo-01.png'},
      {'name': 'النهدي', 'nameEn': 'Nahdi', 'logoUrl': 'https://dam.nahdionline.com/m/64c5f9fc7961125c/original/nahdi-logo-footer.png'},
      {'name': 'الدواء', 'nameEn': 'Al-Dawaa', 'logoUrl': ''},
      {'name': 'لولو', 'nameEn': 'Lulu', 'logoUrl': 'https://gcc.luluhypermarket.com/akn-logo-english.svg'},
      {'name': 'كارفور', 'nameEn': 'Carrefour', 'logoUrl': ''},
      {'name': 'نايكي', 'nameEn': 'Nike', 'logoUrl': 'https://icon.horse/icon/nike.com'},
      {'name': 'أديداس', 'nameEn': 'Adidas', 'logoUrl': 'https://icon.horse/icon/adidas.com'},
      {'name': 'فانز', 'nameEn': 'Vans', 'logoUrl': 'https://icon.horse/icon/vans.com'},
      {'name': 'سن أند ساند', 'nameEn': 'Sun & Sand', 'logoUrl': 'https://icon.horse/icon/sssports.com'},
      {'name': 'هدى بيوتي', 'nameEn': 'Huda Beauty', 'logoUrl': 'https://icon.horse/icon/hudabeauty.com'},
      {'name': 'أندير آرمور', 'nameEn': 'Under Armour', 'logoUrl': 'https://icon.horse/icon/underarmour.com'},
      {'name': 'ماماز آند باباز', 'nameEn': 'Mamas & Papas', 'logoUrl': 'https://mamasandpapas.ae/on/demandware.static/Sites-MnP_AE-Site/-/default/dw8b06063c/images/logo.svg'},
      {'name': 'بوما', 'nameEn': 'Puma', 'logoUrl': 'https://sa.puma.com/static/frontend/scandipwa/theme/en_US/Magento_Theme/static/media/puma.b1cfa416.svg'},
      {'name': 'ناتشورال تاتش', 'nameEn': 'Natural Touch', 'logoUrl': 'https://media.zid.store/cdn-cgi/image/h=200,q=75,f=auto/https://media.zid.store/d3b973ce-4213-438e-a687-c37fd0413f43/3f4e438f-b022-4e27-8d1a-6171ffd640bf.png'},
    ];

    final Map<String, Map<String, dynamic>> seen = {};

    // 1. Add stores that currently have active coupons (Prioritize them)
    for (var c in coupons) {
      final name = c.storeName;
      if (!seen.containsKey(name)) {
        seen[name] = {
          'name': name,
          'nameEn': name,
          'logoUrl': resolveStoreLogoUrl(
            storeId: c.storeId,
            productUrl: '',
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
    
    final text = (isCarrefour || isAldawaa) ? name : (name.isNotEmpty ? name.characters.first : '?');
    
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
