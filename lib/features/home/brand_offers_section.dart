import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandOffersSection extends StatelessWidget {
  const BrandOffersSection({super.key});

  static const List<Map<String, dynamic>> stores = [
    // ── الشركاء (لديهم كود خصم) ──
    {
      'name': 'دار الاميرات',
      'nameEn': 'Dar Al-Amirat',
      'url': 'https://mtjr.at/FN2AIl2KWs',
      'color': Color(0xFFE91E63),
      'hasCoupon': true,
    },
    {
      'name': 'اضاحي كبش نجد',
      'nameEn': 'Kabsh Najd',
      'url': 'https://mtjr.at/_2-N8J8JYq',
      'color': Color(0xFF8D6E63),
      'hasCoupon': true,
    },
    {
      'name': 'ڤانير',
      'nameEn': 'Vanier',
      'url': 'https://mtjr.at/llD-L7SGIe',
      'color': Color(0xFF9C27B0),
      'hasCoupon': true,
    },
    {
      'name': 'رشفة ذكرى',
      'nameEn': 'Rashfa Dhikra',
      'url': 'https://mtjr.at/dKbDAZu6uC',
      'color': Color(0xFF8B4513),
      'hasCoupon': true,
    },
    {
      'name': 'روشن',
      'nameEn': 'Roshen',
      'url': 'https://mtjr.at/yyIPYOIhZT',
      'color': Color(0xFF1565C0),
      'hasCoupon': true,
    },
    {
      'name': 'روشن تذاكر كاس العالم',
      'nameEn': 'Roshen World Cup',
      'url': 'https://mtjr.at/Q5bZQdUrJ4',
      'color': Color(0xFF2E7D32),
      'hasCoupon': true,
    },
    {
      'name': 'فتبول',
      'nameEn': 'Futbol',
      'url': 'https://mtjr.at/e7RHqtq2c5',
      'color': Color(0xFFE65100),
      'hasCoupon': true,
    },
    {
      'name': 'الريم للعبايات',
      'nameEn': 'Al-Reem',
      'url': 'https://mtjr.at/ce3e1xVX7Y',
      'color': Color(0xFF4A148C),
      'hasCoupon': true,
    },
    {
      'name': 'فايب',
      'nameEn': 'Vibe',
      'url': 'https://mtjr.at/1H0-ZC1QMn',
      'color': Color(0xFFFF8F00),
      'hasCoupon': true,
    },
    {
      'name': 'قطرة عسل',
      'nameEn': 'Qatret Asal',
      'url': 'https://mtjr.at/zCUaC5F9e4',
      'color': Color(0xFFFFB300),
      'hasCoupon': true,
    },
    // ── المتاجر السعودية ──
    {
      'name': 'أمازون',
      'nameEn': 'Amazon',
      'url': 'https://www.amazon.sa/',
      'color': Color(0xFFFF9900),
      'logoUrl': 'https://icon.horse/icon/amazon.sa',
      'hasCoupon': false,
    },
    {
      'name': 'نون',
      'nameEn': 'Noon',
      'url': 'https://www.noon.com/saudi-ar/',
      'color': Color(0xFFFEE70B),
      'logoUrl': 'https://icon.horse/icon/noon.com',
      'hasCoupon': false,
    },
    {
      'name': 'نمشي',
      'nameEn': 'Namshi',
      'url': 'https://www.namshi.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://icon.horse/icon/namshi.com',
      'hasCoupon': false,
    },
    {
      'name': 'جرير',
      'nameEn': 'Jarir',
      'url': 'https://www.jarir.com/',
      'color': Color(0xFFC62828),
      'logoUrl': 'https://icon.horse/icon/jarir.com',
      'hasCoupon': false,
    },
    {
      'name': 'إكسترا',
      'nameEn': 'Extra',
      'url': 'https://www.extra.com/',
      'color': Color(0xFF00695C),
      'logoUrl': 'https://icon.horse/icon/extra.com',
      'hasCoupon': false,
    },
    {
      'name': 'بنده',
      'nameEn': 'Panda',
      'url': 'https://www.panda.sa/',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://icon.horse/icon/panda.sa',
      'hasCoupon': false,
    },
    {
      'name': 'العثيم',
      'nameEn': 'Othaim',
      'url': 'https://www.othaimmarkets.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://icon.horse/icon/othaimmarkets.com',
      'hasCoupon': false,
    },
    {
      'name': 'التميمي',
      'nameEn': 'Tamimi',
      'url': 'https://www.tamimimarkets.com/',
      'color': Color(0xFFE65100),
      'logoUrl': 'https://icon.horse/icon/tamimimarkets.com',
      'hasCoupon': false,
    },
    {
      'name': 'النهدي',
      'nameEn': 'Nahdi',
      'url': 'https://www.nahdi.com.sa/',
      'color': Color(0xFF0D47A1),
      'logoUrl': 'https://icon.horse/icon/nahdi.com.sa',
      'hasCoupon': false,
    },
    {
      'name': 'الدواء',
      'nameEn': 'Al-Dawaa',
      'url': 'https://www.aldawaa.com/',
      'color': Color(0xFF1B5E20),
      'logoUrl': 'https://icon.horse/icon/aldawaa.com',
      'hasCoupon': false,
    },
    {
      'name': 'لولو',
      'nameEn': 'Lulu',
      'url': 'https://www.luluhypermarket.com/',
      'color': Color(0xFFD32F2F),
      'logoUrl': 'https://icon.horse/icon/luluhypermarket.com',
      'hasCoupon': false,
    },
    {
      'name': 'كارفور',
      'nameEn': 'Carrefour',
      'url': 'https://www.carrefourksa.com/',
      'color': Color(0xFF004D99),
      'logoUrl': 'https://icon.horse/icon/carrefourksa.com',
      'hasCoupon': false,
    },
    // ── متاجر عالمية (روابط أفليت) ──
    {
      'name': 'نايكي',
      'nameEn': 'Nike',
      'url': 'https://www.nike.sa/en/home/',
      'color': Colors.black,
      'logoUrl': 'https://icon.horse/icon/nike.com',
      'hasCoupon': false,
    },
    {
      'name': 'H&M',
      'nameEn': 'H&M',
      'url': 'https://ae.hm.com/en/',
      'color': Color(0xFFCF1126),
      'logoUrl': 'https://icon.horse/icon/hm.com',
      'hasCoupon': false,
    },
    {
      'name': 'سن أند ساند',
      'nameEn': 'Sun & Sand',
      'url': 'https://en-ae.sssports.com/',
      'color': Color(0xFFE30613),
      'logoUrl': 'https://icon.horse/icon/sssports.com',
      'hasCoupon': false,
    },
    {
      'name': 'هدى بيوتي',
      'nameEn': 'Huda Beauty',
      'url': 'https://hudabeauty.com/en-sa/',
      'color': Color(0xFF231F20),
      'logoUrl': 'https://icon.horse/icon/hudabeauty.com',
      'hasCoupon': false,
    },
    {
      'name': 'YSL Beauty',
      'nameEn': 'YSL Beauty',
      'url': 'https://www.yslbeauty.sa/',
      'color': Colors.black,
      'logoUrl': 'https://icon.horse/icon/yslbeauty.sa',
      'hasCoupon': false,
    },
    {
      'name': 'أندير آرمور',
      'nameEn': 'Under Armour',
      'url': 'https://www.underarmour.ae/en/home',
      'color': Color(0xFF1D1D1D),
      'logoUrl': 'https://icon.horse/icon/underarmour.com',
      'hasCoupon': false,
    },
    {
      'name': 'ماماز آند باباز',
      'nameEn': 'Mamas & Papas',
      'url': 'https://mamasandpapas.ae/',
      'color': Color(0xFF4A4A4A),
      'logoUrl': 'https://icon.horse/icon/mamasandpapas.ae',
      'hasCoupon': false,
    },
    {
      'name': 'بلومينغديلز',
      'nameEn': 'Bloomingdale\'s',
      'url': 'https://bloomingdales.ae/',
      'color': Colors.black,
      'logoUrl': 'https://icon.horse/icon/bloomingdales.ae',
      'hasCoupon': false,
    },
    {
      'name': 'بوما',
      'nameEn': 'Puma',
      'url': 'https://sa.puma.com/en/',
      'color': Color(0xFFBA0C2F),
      'logoUrl': 'https://icon.horse/icon/puma.com',
      'hasCoupon': false,
    },
    {
      'name': 'ناتشورال تاتش',
      'nameEn': 'Natural Touch',
      'url': 'https://ntshop.sa/',
      'color': Color(0xFF1B5E20),
      'logoUrl': 'https://icon.horse/icon/ntshop.sa',
      'hasCoupon': false,
    },
  ];

  Future<void> _launchBrand(String url) async {
    final affiliateUrl = AffiliateLinkService.prepareForOpen(url);
    final uri = Uri.parse(affiliateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  Widget _buildLogo(Map<String, dynamic> store, Color color) {
    final logoUrl = store['logoUrl'] as String?;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildLetterAvatar(store, color),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildLetterAvatar(store, color);
  }

  Widget _buildLetterAvatar(Map<String, dynamic> store, Color color) {
    final name = (store['name'] as String? ?? '');
    final firstChar = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: AppPalette.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                tr('المتاجر', 'Stores'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.navy,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final store = stores[index];
              final color = store['color'] as Color;
              final hasCoupon = store['hasCoupon'] as bool;
              return GestureDetector(
                onTap: () => _launchBrand(store['url']),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: hasCoupon ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasCoupon
                              ? color.withValues(alpha: 0.3)
                              : color.withValues(alpha: 0.15),
                          width: hasCoupon ? 1.5 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(child: _buildLogo(store, color)),
                          if (hasCoupon)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPalette.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tr('كود', 'CODE'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 90,
                      child: Text(
                        tr(store['name'], store['nameEn']),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.navy,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
