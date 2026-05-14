import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/seed/salla_affiliate_seed.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandOffersSection extends StatelessWidget {
  const BrandOffersSection({super.key});

  static final List<Map<String, dynamic>> stores = [
    // ── الشركاء (لديهم كود خصم) ──
    {
      'name': 'دار الاميرات',
      'nameEn': 'Dar Al-Amirat',
      'url': 'https://mtjr.at/FN2AIl2KWs',
      'color': Color(0xFFE91E63),
      'logoUrl':
          'https://cdn.files.salla.network/homepage/1945128061/614d2162-eb21-4042-b1e3-d6d7b9286f0e.webp',
      'hasCoupon': true,
    },
    {
      'name': 'اضاحي كبش نجد',
      'nameEn': 'Kabsh Najd',
      'url': 'https://mtjr.at/_2-N8J8JYq',
      'color': Color(0xFF8D6E63),
      'logoUrl':
          'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/weVoN/0UmHZNzzcSTsJFxoUS7XUA44FKjBooAoaYdnBMRC.png',
      'hasCoupon': true,
    },
    {
      'name': 'ڤانير',
      'nameEn': 'Vanier',
      'url': 'https://mtjr.at/llD-L7SGIe',
      'color': Color(0xFF9C27B0),
      'logoUrl':
          'https://cdn.salla.sa/form-builder/PjqfVf7MC9Hk7RM5bnEot4UibG0L9y9x3ZgOvZfY.png',
      'hasCoupon': true,
    },
    {
      'name': 'رشفة ذكرى',
      'nameEn': 'Rashfa Dhikra',
      'url': 'https://mtjr.at/dKbDAZu6uC',
      'color': Color(0xFF8B4513),
      'logoUrl':
          'https://cdn.files.salla.network/theme/345471826/193dff3e-b377-4448-b706-3db43180a89c.webp',
      'hasCoupon': true,
    },
    {
      'name': 'روشن',
      'nameEn': 'Roshen',
      'url': 'https://mtjr.at/yyIPYOIhZT',
      'color': Color(0xFF1565C0),
      'logoUrl':
          'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/YgzZmQ/I56MKkmn1AEjl84eqSzXmk2emQQus6kYLDRW1UEo.png',
      'hasCoupon': true,
    },
    {
      'name': 'روشن تذاكر كاس العالم',
      'nameEn': 'Roshen World Cup',
      'url': 'https://mtjr.at/Q5bZQdUrJ4',
      'color': Color(0xFF2E7D32),
      'logoUrl':
          'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/YgzZmQ/I56MKkmn1AEjl84eqSzXmk2emQQus6kYLDRW1UEo.png',
      'hasCoupon': true,
    },
    {
      'name': 'فتبول',
      'nameEn': 'Futbol',
      'url': 'https://mtjr.at/e7RHqtq2c5',
      'color': Color(0xFFE65100),
      'logoUrl':
          'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/wjRK/SfsYlKNePyTmQ7H7MkvaNErzbXPYy8hjY1M47OxT.png',
      'hasCoupon': true,
    },
    {
      'name': 'الريم للعبايات',
      'nameEn': 'Al-Reem',
      'url': 'https://mtjr.at/ce3e1xVX7Y',
      'color': Color(0xFF4A148C),
      'logoUrl':
          'https://pps.whatsapp.net/v/t61.24694-24/473406790_1156112419527865_8391810256617029679_n.jpg?ccb=11-4&oh=01_Q5Aa4gHgZWvHYcvEtReDV3fGqekBSrEJR9oN_0GH5LIPtuqksw&oe=6A08D3E0&_nc_sid=5e03e0&_nc_cat=108',
      'hasCoupon': true,
    },
    {
      'name': 'فايب',
      'nameEn': 'Vibe',
      'url': 'https://mtjr.at/1H0-ZC1QMn',
      'color': Color(0xFFFF8F00),
      'logoUrl':
          'https://cdn.files.salla.network/theme/186398311/bd0cd056-72e4-41a8-af34-5177d3ac5b14.webp',
      'hasCoupon': true,
    },
    {
      'name': 'قطرة عسل',
      'nameEn': 'Qatret Asal',
      'url': 'https://mtjr.at/zCUaC5F9e4',
      'color': Color(0xFFFFB300),
      'logoUrl':
          'https://cdn.files.salla.network/theme/601093752/565617a9-1dbd-456c-837c-e68b11434516.webp',
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
      'logoUrl': 'https://www.panda.sa/_next/static/media/logo.f85b0530.svg',
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
      'logoUrl': 'https://www.tamimimarkets.com/__template/images/logo-01.png',
      'hasCoupon': false,
    },
    {
      'name': 'النهدي',
      'nameEn': 'Nahdi',
      'url': 'https://www.nahdionline.com/ar-sa/promo-flyer/clp',
      'color': Color(0xFF0D47A1),
      'logoUrl':
          'https://dam.nahdionline.com/m/64c5f9fc7961125c/original/nahdi-logo-footer.png',
      'hasCoupon': false,
    },
    {
      'name': 'الدواء',
      'nameEn': 'Al-Dawaa',
      'url': 'https://www.aldawaa.com/',
      'color': Color(0xFF1B5E20),
      'logoUrl': '',
      'hasCoupon': false,
    },
    {
      'name': 'لولو',
      'nameEn': 'Lulu',
      'url': 'https://www.luluhypermarket.com/',
      'color': Color(0xFFD32F2F),
      'logoUrl': 'https://gcc.luluhypermarket.com/akn-logo-english.svg',
      'hasCoupon': false,
    },
    {
      'name': 'كارفور',
      'nameEn': 'Carrefour',
      'url': 'https://www.carrefourksa.com/',
      'color': Color(0xFF004D99),
      'logoUrl': '', // Using stylized text fallback to avoid 404/CORS issues
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
      'logoUrl':
          'https://mamasandpapas.ae/on/demandware.static/Sites-MnP_AE-Site/-/default/dw8b06063c/images/logo.svg',
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
      'logoUrl':
          'https://sa.puma.com/static/frontend/scandipwa/theme/en_US/Magento_Theme/static/media/puma.b1cfa416.svg',
      'hasCoupon': false,
    },
    {
      'name': 'ناتشورال تاتش',
      'nameEn': 'Natural Touch',
      'url': 'https://ntshop.sa/',
      'color': Color(0xFF1B5E20),
      'logoUrl':
          'https://media.zid.store/cdn-cgi/image/h=200,q=75,f=auto/https://media.zid.store/d3b973ce-4213-438e-a687-c37fd0413f43/3f4e438f-b022-4e27-8d1a-6171ffd640bf.png',
      'hasCoupon': false,
    },
    ...SallaAffiliateSeed.stores.map(
      (store) => {
        'id': store['id'],
        'name': store['name'],
        'nameEn': store['nameEn'],
        'url': store['url'],
        'color': _affiliateCategoryColor(store['category'] as String?),
        'logoUrl': store['logoUrl'],
        'hasCoupon':
            ((store['couponCode'] as String?)?.trim().isNotEmpty ?? false),
      },
    ),
  ];

  static Color _affiliateCategoryColor(String? category) {
    switch (category) {
      case 'fashion':
        return const Color(0xFFD81B60);
      case 'shoes':
        return const Color(0xFF1A237E);
      case 'beauty':
        return const Color(0xFF9C27B0);
      case 'jewelry':
        return const Color(0xFFB8860B);
      case 'electronics':
        return const Color(0xFF00695C);
      default:
        return AppPalette.orange;
    }
  }

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
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          width: 75,
          height: 75,
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
    final nameEn = (store['nameEn'] as String? ?? '').toLowerCase();
    final isCarrefour = name == 'كارفور' || nameEn == 'carrefour';
    final isAldawaa = name == 'الدواء' || nameEn == 'al-dawaa';
    final textToShow = (isCarrefour || isAldawaa)
        ? name
        : (name.isNotEmpty ? name.characters.first : '?');

    Color textColor = AppPalette.orange;
    if (isCarrefour) textColor = const Color(0xFF003087);
    if (isAldawaa) textColor = Colors.black;

    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: isAldawaa
            ? Colors.black.withValues(alpha: 0.05)
            : AppPalette.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          textToShow,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: (isCarrefour || isAldawaa) ? 18 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: (isCarrefour || isAldawaa) ? -0.5 : 0,
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
          height: 145,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final store = stores[index];
              final color = store['color'] as Color;
              final hasCoupon = store['hasCoupon'] as bool;
              final isAldawaa = store['name'] == 'الدواء' ||
                  (store['nameEn'] as String? ?? '').toLowerCase() ==
                      'al-dawaa';

              return GestureDetector(
                onTap: () => _launchBrand(store['url']),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isAldawaa
                            ? Colors.black.withValues(alpha: 0.05)
                            : AppPalette.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isAldawaa
                              ? Colors.black.withValues(alpha: 0.15)
                              : AppPalette.orange.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isAldawaa
                                ? Colors.black.withValues(alpha: 0.1)
                                : AppPalette.orange.withValues(alpha: 0.15),
                            blurRadius: isAldawaa ? 12 : 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isAldawaa
                              ? Colors.black.withValues(alpha: 0.05)
                              : AppPalette.orange
                                  .withValues(alpha: hasCoupon ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(20),
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
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: Text(
                        tr(store['name'], store['nameEn']),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.brandNavyDeep,
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
