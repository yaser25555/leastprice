import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/store_offers_screen.dart';

class PopularStoresSection extends StatelessWidget {
  const PopularStoresSection({super.key});

  static const List<Map<String, dynamic>> stores = [
    {
      'id': 'noon',
      'name': 'نون',
      'nameEn': 'Noon',
      'url': 'https://s.noon.com/HOTtsN31XfI',
      'color': Color(0xFFFEE70B),
      'logoUrl': 'https://logo.clearbit.com/noon.com',
    },
    {
      'id': 'amazon',
      'name': 'أمازون',
      'nameEn': 'Amazon',
      'url': 'https://www.amazon.sa/',
      'color': Color(0xFFFF9900),
      'logoUrl': 'https://logo.clearbit.com/amazon.sa',
    },
    {
      'id': 'keeta',
      'name': 'كيتا',
      'nameEn': 'Keeta',
      'url': 'https://keeta.com/',
      'color': Color(0xFFFF6B35),
    },
    {
      'id': 'hungerstation',
      'name': 'هنجرستيشن',
      'nameEn': 'HungerStation',
      'url': 'https://www.hungerstation.com/',
      'color': Color(0xFFE91E63),
    },
    {
      'id': 'panda',
      'name': 'بنده',
      'nameEn': 'Panda',
      'url': 'https://www.panda.sa/',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://logo.clearbit.com/panda.sa',
    },
    {
      'id': 'othaim',
      'name': 'العثيم',
      'nameEn': 'Othaim',
      'url': 'https://www.othaimmarkets.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://logo.clearbit.com/othaimmarkets.com',
    },
    {
      'id': 'tamimi',
      'name': 'التميمي',
      'nameEn': 'Tamimi',
      'url': 'https://www.tamimimarkets.com/',
      'color': Color(0xFFE65100),
      'logoUrl': 'https://logo.clearbit.com/tamimimarkets.com',
    },
    {
      'id': 'extra',
      'name': 'إكسترا',
      'nameEn': 'Extra',
      'url': 'https://www.extra.com/',
      'color': Color(0xFF00695C),
      'logoUrl': 'https://logo.clearbit.com/extra.com',
    },
    {
      'id': 'jarir',
      'name': 'جرير',
      'nameEn': 'Jarir',
      'url': 'https://www.jarir.com/',
      'color': Color(0xFFC62828),
      'logoUrl': 'https://logo.clearbit.com/jarir.com',
    },
    {
      'id': 'nahdi',
      'name': 'النهدي',
      'nameEn': 'Nahdi',
      'url': 'https://www.nahdi.com.sa/',
      'color': Color(0xFF0D47A1),
      'logoUrl': 'https://logo.clearbit.com/nahdi.com.sa',
    },
    {
      'id': 'aldawaa',
      'name': 'الدواء',
      'nameEn': 'Al-Dawaa',
      'url': 'https://www.aldawaa.com/',
      'color': Color(0xFF1B5E20),
      'logoUrl': 'https://logo.clearbit.com/aldawaa.com',
    },
    {
      'id': 'lulu',
      'name': 'لولو',
      'nameEn': 'Lulu',
      'url': 'https://www.luluhypermarket.com/',
      'color': Color(0xFFD32F2F),
      'logoUrl': 'https://logo.clearbit.com/luluhypermarket.com',
    },
    {
      'id': 'carrefour',
      'name': 'كارفور',
      'nameEn': 'Carrefour',
      'url': 'https://www.carrefourksa.com/',
      'color': Color(0xFF004D99),
      'logoUrl': 'https://logo.clearbit.com/carrefourksa.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.navy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppPalette.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                tr('عروض المتاجر الشهيرة', 'Popular Stores'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.navy,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            tr('تصفّح البدائل الأقل سعراً في أشهر المتاجر',
                'Browse cheaper alternatives at top stores'),
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.navy.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              final color = store['color'] as Color;
              final logoUrl = store['logoUrl'] as String?;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreOffersScreen(
                        storeId: store['id'],
                        storeName: store['name'],
                        storeNameEn: store['nameEn'],
                        storeColor: color,
                        storeLogoUrl: logoUrl,
                        storeUrl: store['url'],
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: logoUrl != null && logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  logoUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildLetter(store, color),
                                ),
                              )
                            : _buildLetter(store, color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        tr(store['name'], store['nameEn']),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.navy,
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

  Widget _buildLetter(Map<String, dynamic> store, Color color) {
    final name = (store['name'] as String? ?? '');
    final char = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
