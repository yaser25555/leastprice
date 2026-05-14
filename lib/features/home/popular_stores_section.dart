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
      'logoUrl': 'https://icon.horse/icon/noon.com',
    },
    {
      'id': 'amazon',
      'name': 'أمازون',
      'nameEn': 'Amazon',
      'url': 'https://www.amazon.sa/',
      'color': Color(0xFFFF9900),
      'logoUrl': 'https://icon.horse/icon/amazon.sa',
    },
    {
      'id': 'keeta',
      'name': 'كيتا',
      'nameEn': 'Keeta',
      'url': 'https://keeta.com/',
      'color': Color(0xFFFF6B35),
      'logoUrl': 'https://img-ap-hongkong.mykeeta.net/sailorfempcpublic/keeta_icon.png',
    },
    {
      'id': 'hungerstation',
      'name': 'هنجرستيشن',
      'nameEn': 'HungerStation',
      'url': 'https://www.hungerstation.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://hungerstation.com/_next/static/media/hungerstation-logo-shadow.f55495d3.svg',
    },
    {
      'id': 'panda',
      'name': 'بنده',
      'nameEn': 'Panda',
      'url': 'https://www.panda.sa/',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://www.panda.sa/_next/static/media/logo.f85b0530.svg',
    },
    {
      'id': 'othaim',
      'name': 'العثيم',
      'nameEn': 'Othaim',
      'url': 'https://www.othaimmarkets.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://icon.horse/icon/othaimmarkets.com',
    },
    {
      'id': 'tamimi',
      'name': 'التميمي',
      'nameEn': 'Tamimi',
      'url': 'https://www.tamimimarkets.com/',
      'color': Color(0xFFE65100),
      'logoUrl': 'https://www.tamimimarkets.com/__template/images/logo-01.png',
    },
    {
      'id': 'extra',
      'name': 'إكسترا',
      'nameEn': 'Extra',
      'url': 'https://www.extra.com/',
      'color': Color(0xFF00695C),
      'logoUrl': 'https://icon.horse/icon/extra.com',
    },
    {
      'id': 'jarir',
      'name': 'جرير',
      'nameEn': 'Jarir',
      'url': 'https://www.jarir.com/',
      'color': Color(0xFFC62828),
      'logoUrl': 'https://icon.horse/icon/jarir.com',
    },
    {
      'id': 'nahdi',
      'name': 'النهدي',
      'nameEn': 'Nahdi',
      'url': 'https://www.nahdionline.com/ar-sa/promo-flyer/clp',
      'color': Color(0xFF0D47A1),
      'logoUrl': 'https://dam.nahdionline.com/m/64c5f9fc7961125c/original/nahdi-logo-footer.png',
    },
    {
      'id': 'aldawaa',
      'name': 'الدواء',
      'nameEn': 'Al-Dawaa',
      'url': 'https://www.aldawaa.com/',
      'color': Color(0xFF1B5E20),
      'logoUrl': '',
    },
    {
      'id': 'lulu',
      'name': 'لولو',
      'nameEn': 'Lulu',
      'url': 'https://www.luluhypermarket.com/',
      'color': Color(0xFFD32F2F),
      'logoUrl': 'https://gcc.luluhypermarket.com/akn-logo-english.svg',
    },
    {
      'id': 'carrefour',
      'name': 'كارفور',
      'nameEn': 'Carrefour',
      'url': 'https://www.carrefourksa.com/',
      'color': Color(0xFF004D99),
      'logoUrl': '', // Using stylized text fallback to avoid 404/CORS issues
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
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              final color = store['color'] as Color;
              final logoUrl = store['logoUrl'] as String?;

              final isAldawaa = store['id'] == 'aldawaa';

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreOffersScreen(
                        storeId: store['id'],
                        storeName: store['name'],
                        storeNameEn: store['nameEn'],
                        storeColor: AppPalette.orange,
                        storeLogoUrl: logoUrl,
                        storeUrl: store['url'],
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: isAldawaa
                            ? Colors.black.withValues(alpha: 0.05)
                            : AppPalette.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isAldawaa
                                ? Colors.black.withValues(alpha: 0.15)
                                : AppPalette.orange.withValues(alpha: 0.4),
                            blurRadius: isAldawaa ? 12 : 20,
                            offset: const Offset(0, 8),
                            spreadRadius: isAldawaa ? -1 : -2,
                          ),
                          BoxShadow(
                            color: AppPalette.navy.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: AppPalette.orange.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Builder(builder: (context) {
                          final proxiedLogoUrl =
                              logoUrl != null ? proxiedImageUrl(logoUrl) : null;
                          return proxiedLogoUrl != null &&
                                  proxiedLogoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    proxiedLogoUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _buildLetter(store, color),
                                  ),
                                )
                              : _buildLetter(store, color);
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 84,
                      child: Text(
                        tr(store['name'], store['nameEn']),
                        textAlign: TextAlign.center,
                        maxLines: 1,
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

  Widget _buildLetter(Map<String, dynamic> store, Color color) {
    final name = (store['name'] as String? ?? '');
    final storeId = store['id'];
    final isCarrefour = storeId == 'carrefour';
    final isAldawaa = storeId == 'aldawaa';
    final textToShow = (isCarrefour || isAldawaa)
        ? name
        : (name.isNotEmpty ? name.characters.first : '?');

    Color textColor = AppPalette.orange;
    if (isCarrefour) textColor = const Color(0xFF003087);
    if (isAldawaa) textColor = Colors.black;

    return Container(
      width: 60,
      height: 60,
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
            fontSize: (isCarrefour || isAldawaa) ? 14 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: (isCarrefour || isAldawaa) ? -0.5 : 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}
