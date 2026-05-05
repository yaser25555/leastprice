import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandOffersSection extends StatelessWidget {
  const BrandOffersSection({super.key});

  static const List<Map<String, dynamic>> brands = [
    {
      'name': 'نون',
      'nameEn': 'Noon',
      'url': 'https://www.noon.com/saudi-ar/',
      'color': Color(0xFFFEE70B),
      'icon': Icons.shopping_cart_rounded,
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
      'name': 'سن أند ساند',
      'nameEn': 'Sun & Sand',
      'url': 'https://en-ae.sssports.com/',
      'color': Color(0xFFE30613),
      'icon': Icons.sports_soccer_rounded,
    },
    {
      'name': 'هدى بيوتي',
      'nameEn': 'Huda Beauty',
      'url': 'https://hudabeauty.com/en-sa/',
      'color': Color(0xFF231F20),
      'icon': Icons.face_retouching_natural_rounded,
    },
    {
      'name': 'YSL Beauty',
      'nameEn': 'YSL Beauty',
      'url': 'https://www.yslbeauty.sa/',
      'color': Colors.black,
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'name': 'أندير آرمور',
      'nameEn': 'Under Armour',
      'url': 'https://www.underarmour.ae/en/home',
      'color': Color(0xFF1D1D1D),
      'icon': Icons.fitness_center_rounded,
    },
    {
      'name': 'ماماز آند باباز',
      'nameEn': 'Mamas & Papas',
      'url': 'https://mamasandpapas.ae/',
      'color': Color(0xFF4A4A4A),
      'icon': Icons.child_friendly_rounded,
    },
    {
      'name': 'بلومينغديلز',
      'nameEn': 'Bloomingdale\'s',
      'url': 'https://bloomingdales.ae/',
      'color': Colors.black,
      'icon': Icons.storefront_rounded,
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
                tr('عروض المتاجر الشريكة', 'Partner Brand Offers'),
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
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final brand = brands[index];
              final isDark = (brand['color'] as Color).computeLuminance() < 0.5;

              return GestureDetector(
                onTap: () => _launchBrand(brand['url']),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: brand['color'],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (brand['color'] as Color)
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          brand['icon'],
                          color: isDark ? Colors.white : AppPalette.navy,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(brand['name'], brand['nameEn']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.navy,
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
