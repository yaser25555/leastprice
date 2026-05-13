import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandOffersSection extends StatelessWidget {
  const BrandOffersSection({super.key});

  static const List<Map<String, dynamic>> partnerBrands = [
    {
      'name': 'دار الاميرات',
      'nameEn': 'Dar Al-Amirat',
      'url': 'https://mtjr.at/FN2AIl2KWs',
      'color': Color(0xFFE91E63),
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'name': 'اضاحي كبش نجد',
      'nameEn': 'Kabsh Najd',
      'url': 'https://mtjr.at/_2-N8J8JYq',
      'color': Color(0xFF8D6E63),
      'icon': Icons.restaurant_rounded,
    },
    {
      'name': 'ڤانير',
      'nameEn': 'Vanier',
      'url': 'https://mtjr.at/llD-L7SGIe',
      'color': Color(0xFF9C27B0),
      'icon': Icons.spa_rounded,
    },
    {
      'name': 'رشفة ذكرى',
      'nameEn': 'Rashfa Dhikra',
      'url': 'https://mtjr.at/dKbDAZu6uC',
      'color': Color(0xFF8B4513),
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'name': 'روشن',
      'nameEn': 'Roshen',
      'url': 'https://mtjr.at/yyIPYOIhZT',
      'color': Color(0xFF1565C0),
      'icon': Icons.checkroom_rounded,
    },
    {
      'name': 'روشن تذاكر كاس العالم',
      'nameEn': 'Roshen World Cup',
      'url': 'https://mtjr.at/Q5bZQdUrJ4',
      'color': Color(0xFF2E7D32),
      'icon': Icons.sports_soccer_rounded,
    },
    {
      'name': 'فتبول',
      'nameEn': 'Futbol',
      'url': 'https://mtjr.at/e7RHqtq2c5',
      'color': Color(0xFFE65100),
      'icon': Icons.directions_run_rounded,
    },
    {
      'name': 'الريم للعبايات',
      'nameEn': 'Al-Reem',
      'url': 'https://mtjr.at/ce3e1xVX7Y',
      'color': Color(0xFF4A148C),
      'icon': Icons.style_rounded,
    },
    {
      'name': 'فايب',
      'nameEn': 'Vibe',
      'url': 'https://mtjr.at/1H0-ZC1QMn',
      'color': Color(0xFFFF8F00),
      'icon': Icons.watch_rounded,
    },
  ];

  static const List<Map<String, dynamic>> popularStores = [
    {
      'name': 'أمازون',
      'nameEn': 'Amazon',
      'url': 'https://www.amazon.sa/',
      'color': Color(0xFFFF9900),
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'name': 'نون',
      'nameEn': 'Noon',
      'url': 'https://www.noon.com/saudi-ar/',
      'color': Color(0xFFFEE70B),
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'name': 'نمشي',
      'nameEn': 'Namshi',
      'url': 'https://www.namshi.com/',
      'color': Color(0xFFE91E63),
      'icon': Icons.checkroom_rounded,
    },
    {
      'name': 'جرير',
      'nameEn': 'Jarir',
      'url': 'https://www.jarir.com/',
      'color': Color(0xFFC62828),
      'icon': Icons.laptop_rounded,
    },
    {
      'name': 'إكسترا',
      'nameEn': 'Extra',
      'url': 'https://www.extra.com/',
      'color': Color(0xFF00695C),
      'icon': Icons.devices_rounded,
    },
    {
      'name': 'بنده',
      'nameEn': 'Panda',
      'url': 'https://www.panda.sa/',
      'color': Color(0xFF2E7D32),
      'icon': Icons.local_grocery_store_rounded,
    },
    {
      'name': 'العثيم',
      'nameEn': 'Othaim',
      'url': 'https://www.othaimmarkets.com/',
      'color': Color(0xFF1565C0),
      'icon': Icons.store_rounded,
    },
    {
      'name': 'التميمي',
      'nameEn': 'Tamimi',
      'url': 'https://www.tamimimarkets.com/',
      'color': Color(0xFFE65100),
      'icon': Icons.local_grocery_store_rounded,
    },
    {
      'name': 'النهدي',
      'nameEn': 'Nahdi',
      'url': 'https://www.nahdi.com.sa/',
      'color': Color(0xFF0D47A1),
      'icon': Icons.local_pharmacy_rounded,
    },
    {
      'name': 'الدواء',
      'nameEn': 'Al-Dawaa',
      'url': 'https://www.aldawaa.com/',
      'color': Color(0xFF1B5E20),
      'icon': Icons.local_pharmacy_rounded,
    },
    {
      'name': 'لولو',
      'nameEn': 'Lulu',
      'url': 'https://www.luluhypermarket.com/',
      'color': Color(0xFFD32F2F),
      'icon': Icons.storefront_rounded,
    },
    {
      'name': 'كارفور',
      'nameEn': 'Carrefour',
      'url': 'https://www.carrefourksa.com/',
      'color': Color(0xFF004D99),
      'icon': Icons.shopping_basket_rounded,
    },
    {
      'name': 'نايكي',
      'nameEn': 'Nike',
      'url': 'https://www.nike.sa/en/home/',
      'color': Colors.black,
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'H&M',
      'nameEn': 'H&M',
      'url': 'https://ae.hm.com/en/',
      'color': Color(0xFFCF1126),
      'icon': Icons.checkroom_rounded,
    },
    {
      'name': 'بوما',
      'nameEn': 'Puma',
      'url': 'https://sa.puma.com/en/',
      'color': Color(0xFFBA0C2F),
      'icon': Icons.directions_run_rounded,
    },
  ];

  Future<void> _launchBrand(String url) async {
    final affiliateUrl = AffiliateLinkService.prepareForOpen(url);
    final uri = Uri.parse(affiliateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.stars_rounded,
          title: tr('المتاجر الشريكة', 'Partner Stores'),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: partnerBrands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final brand = partnerBrands[index];
              final isDark =
                  (brand['color'] as Color).computeLuminance() < 0.5;
              return _PartnerCard(
                brand: brand,
                isDark: isDark,
                onTap: () => _launchBrand(brand['url']),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.grey.shade200),
        ),
        _buildSectionHeader(
          context,
          icon: Icons.storefront_rounded,
          title: tr('المتاجر الشهيرة', 'Popular Stores'),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: popularStores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = popularStores[index];
              final isDark =
                  (store['color'] as Color).computeLuminance() < 0.5;
              return GestureDetector(
                onTap: () => _launchBrand(store['url']),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: store['color'],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          store['icon'],
                          color: isDark ? Colors.white : AppPalette.navy,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(store['name'], store['nameEn']),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppPalette.orange, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppPalette.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.brand,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> brand;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = brand['color'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    brand['icon'],
                    color: color,
                    size: 38,
                  ),
                ),
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
              tr(brand['name'], brand['nameEn']),
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
  }
}
