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
    {
      'id': 'itsmine',
      'name': 'اتزماين',
      'nameEn': 'Itsmine',
      'url': 'https://itsminesa.com/',
      'color': Color(0xFFD81B60),
      'logoUrl': 'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/RNqgx/g7t1WwklZEv0MBi1l8UXmI8wHHPVfhbYOt6hE2Em.png',
    },
    {
      'id': 'goldlolwa',
      'name': 'لمعة اللؤلؤة',
      'nameEn': 'Gold Lolwa',
      'url': 'https://goldlolwa.com/',
      'color': Color(0xFFB8860B),
      'logoUrl': 'https://cdn.salla.sa/form-builder/6O3ALxj3G9WBPCTaSWydXRDRwutZHHI153Jbxy5z.png',
    },
    {
      'id': 'algharbi',
      'name': 'الغربي',
      'nameEn': 'Al-Gharbi',
      'url': 'https://algharbis.com/',
      'color': Color(0xFF5D4037),
      'logoUrl': 'https://cdn.files.salla.network/theme/2015884868/e6d46e9c-b114-4d9c-ac31-37522b369b3c.webp',
    },
    {
      'id': 'mshkatmran',
      'name': 'مشكاة مران',
      'nameEn': 'Mshkat Mran',
      'url': 'https://mshkatmran.com/',
      'color': Color(0xFF558B2F),
      'logoUrl': 'https://cdn.salla.sa/mmXOE/cSikL3jGCNx5pwaWgRBPQ6XyyHJcGHOM49yic0Ey.png',
    },
    {
      'id': 'alhawwaj',
      'name': 'الحواج',
      'nameEn': 'Al-Hawwaj',
      'url': 'https://alhawwaj.com/',
      'color': Color(0xFFBF360C),
      'logoUrl': 'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/rAQjG/kJhGt4Op8XpbKyoU72xA3TnXzl5ELkHMNkSIMyD2.png',
    },
    {
      'id': 'threeq',
      'name': 'ثلاث أرباع',
      'nameEn': '3Q',
      'url': 'https://3q.sa/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://cdn.salla.sa/cdn-cgi/image/fit=scale-down,width=400,height=400,onerror=redirect,format=auto/KyOpB/uueqzYPAWfI0mBIl20059dQbnbuh2JSOmIjnRGUu.png',
    },
    {
      'id': 'swanky',
      'name': 'SWANKY',
      'nameEn': 'SWANKY',
      'url': 'https://swanky-road.sa/',
      'color': Color(0xFF4E342E),
      'logoUrl': 'https://cdn.files.salla.network/theme/511691211/797e0758-06c8-494a-92ce-35b20adc7e5b.webp',
    },
    {
      'id': 'shaving360',
      'name': 'Shaving360',
      'nameEn': 'Shaving360',
      'url': 'https://shaving360.com/',
      'color': Color(0xFF263238),
      'logoUrl': 'https://cdn.files.salla.network/theme/1734728887/22a54f79-a035-4490-afac-5e4bf40c1bea.webp',
    },
    {
      'id': 'mtjr',
      'name': 'ليدرز',
      'nameEn': 'Leaders',
      'url': 'https://leaderschairs.com/ar/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://cdn.salla.sa/PQwnK/Bj5UBZjz6DbYPhoAcxOPgm58UfhxnAo18RvI0faY.png',
    },
    {
      'id': 'smarthub1',
      'name': 'سمارت هب 1',
      'nameEn': 'Smart Hub 1',
      'url': 'https://smarthubone.com/',
      'color': Color(0xFF00838F),
      'logoUrl': 'https://cdn.salla.sa/EpBKR/Ac6ymookUMDXq2L7hLkuEqP3ny2jBC8dvEFAHdDP.png',
    },
    {
      'id': 'ragroastery',
      'name': 'RAG Roastery',
      'nameEn': 'RAG Roastery',
      'url': 'https://salla.sa/Ragroastery1',
      'color': Color(0xFF6D4C41),
      'logoUrl': 'https://cdn.files.salla.network/theme/963700998/df8231d6-12b9-46e4-b41b-40cc64f36045.webp',
    },
    {
      'id': 'rakla',
      'name': 'ركله',
      'nameEn': 'Rakla',
      'url': 'https://raklastore.com/',
      'color': Color(0xFF1A237E),
      'logoUrl': 'https://cdn.salla.sa/VqwVgO/7Csrae0bBHt22HETpM190EQV2cNOnxKVsgu8nWTu.png',
    },
    {
      'id': 'burgundy',
      'name': 'Burgundy',
      'nameEn': 'Burgundy',
      'url': 'https://burgundyjewellery.com/',
      'color': Color(0xFF800020),
      'logoUrl': 'https://cdn.salla.sa/YgpPPa/V1nzDJe6cXAmwGd0J8DUDwuDvvTz4GHpGFtOUKr8.png',
    },
    {
      'id': 'takecard',
      'name': 'Take Card',
      'nameEn': 'Take Card',
      'url': 'https://take-card.com/',
      'color': Color(0xFF00ACC1),
      'logoUrl': 'https://cdn.salla.sa/NDVOD/HFMzHbwAZ9M7gEvRzmay9E4U9hMwGyoktGJdmdvw.png',
    },
    {
      'id': 'sadacards',
      'name': 'سدا كاردز',
      'nameEn': 'Sada Cards',
      'url': 'https://sadacards.com/',
      'color': Color(0xFFE65100),
      'logoUrl': 'https://cdn.salla.sa/gZGbzb/aJFHG0R2LGkUscITxfefqIdAJH1w7yZ4E9r6j5jv.png',
    },
    {
      'id': 'alanood',
      'name': 'العنود للأزياء',
      'nameEn': 'Al Anood Fashion',
      'url': 'https://alanoodfashion.com/',
      'color': Color(0xFFD81B60),
      'logoUrl': 'https://cdn.salla.sa/nVrVy/Tjj4D7CiqEbp2SxPth363vx76G5yrqiklhtiK4NU.png',
    },
    {
      'id': 'herfitness',
      'name': 'Her Fitness',
      'nameEn': 'Her Fitness',
      'url': 'https://herfitnessksa.com/',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://cdn.salla.sa/bmznn/8gXJXD3yEADsCMe3Za5OzzLdYqEe7nwS3zSKeFLu.png',
    },
    {
      'id': 'eseven',
      'name': 'E-SEVEN',
      'nameEn': 'E-SEVEN',
      'url': 'https://eseven-store.com/',
      'color': Color(0xFF37474F),
      'logoUrl': 'https://cdn.salla.sa/RvPxw/761qfZ1kkS6QtDXX2ppJrlMfyXexwb3qG5NPxFJL.png',
    },
    {
      'id': 'cozmazone',
      'name': 'كوزمازون',
      'nameEn': 'Cozmazone',
      'url': 'https://cozmazone.com/',
      'color': Color(0xFFAD1457),
      'logoUrl': 'https://cdn.files.salla.network/theme/1515115134/6f3dc3f2-f72b-40a4-9bf6-5ceb671b3397.webp',
    },
    {
      'id': 'bckyrdbbq',
      'name': 'عالم الشواء',
      'nameEn': 'Bckyrd BBQ',
      'url': 'https://bckyrdbbq.com/',
      'color': Color(0xFFBF360C),
      'logoUrl': 'https://cdn.files.salla.network/theme/1333909099/cd31e988-02e3-424a-96d6-eb973e0fa51f.webp',
    },
    {
      'id': 'freesia',
      'name': 'فريسيا',
      'nameEn': 'Freesia',
      'url': 'https://freesiashop.com/',
      'color': Color(0xFF8E24AA),
      'logoUrl': 'https://cdn.salla.sa/VlyP/ndlln3gQJ9mW9m0GhDhzprf77ZtU9KGG51wD4RHi.jpg',
    },
    {
      'id': 'kilmananoud',
      'name': 'كلمنتان للعود',
      'nameEn': 'Kilmantan Oud',
      'url': 'https://kilmantanoud.com/',
      'color': Color(0xFF4E342E),
      'logoUrl': 'https://cdn.files.salla.network/theme/989087173/203cfdd5-151f-4e91-a381-9e6c03da4071.webp',
    },
    {
      'id': 'worldgivenchy',
      'name': 'عالم جيفنشي',
      'nameEn': 'World Givenchy',
      'url': 'https://worldgivenchy.com/',
      'color': Color(0xFF1A237E),
      'logoUrl': 'https://cdn.files.salla.network/theme/1891860617/1c9f96bb-6f1f-4b4a-9179-4c748cc2c563.webp',
    },
    {
      'id': 'bkam',
      'name': 'بكم',
      'nameEn': 'Bkam',
      'url': 'https://b-kam.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://cdn.salla.sa/mWzeP/2Q22fa9Gm60EG4r6pdTjpMWe42l1zjSzILzHKwME.png',
    },
    {
      'id': 'retskin',
      'name': 'ريتسكين',
      'nameEn': 'Retskin',
      'url': 'https://retskin.com/',
      'color': Color(0xFFC2185B),
      'logoUrl': 'https://cdn.salla.sa/yxRq/zqYmK7iJ04G8cmxmZqzJQha2pZ9IMxBxf0GN33Qp.png',
    },
    {
      'id': 'madyalteb',
      'name': 'ماضي الطيب',
      'nameEn': 'Mady Alteb',
      'url': 'https://madyalteb.com/',
      'color': Color(0xFF5D4037),
      'logoUrl': 'https://cdn.salla.sa/RnqQx/hm0NpnEVpxsWWQviyZ7T0RYhQMRGvtkqebjTsFOq.png',
    },
    {
      'id': 'marsil',
      'name': 'مارسيل',
      'nameEn': 'Marsil',
      'url': 'https://marsilstores.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.salla.sa/DGQBBb/a0Ar4GvGMN00x58cO3MM0rUEhfwIXI2cGMPDVeHT.png',
    },
    {
      'id': 'almoqtas',
      'name': 'المختص',
      'nameEn': 'Almoqtas',
      'url': 'https://almoqtas.com/',
      'color': Color(0xFFE53935),
      'logoUrl': 'https://cdn.salla.sa/nvrbb/ANcaTUwH8T6fXCeNrpdCuTbYCkkj5jl368JFCDuA.png',
    },
    {
      'id': 'mlay',
      'name': 'ملاي',
      'nameEn': 'Mlay',
      'url': 'https://mlaystor.com/',
      'color': Color(0xFF7B1FA2),
      'logoUrl': 'https://cdn.salla.sa/YDdRl/VUtJDnuh75EkhGMbO0h2ad8VL3P3ZuR2xoZ87S3v.png',
    },
    {
      'id': 'laveen',
      'name': 'لاڤين عباية',
      'nameEn': 'Laveen Abaya',
      'url': 'https://laveenabaya.com/',
      'color': Color(0xFFAD1457),
      'logoUrl': 'https://cdn.salla.sa/BYEEV/nwpvtKYcvRREjakwkM0BSgg2ogEawfsjNuPpi4Ki.png',
    },
    {
      'id': 'ayworlds',
      'name': 'عالم ايوا',
      'nameEn': 'Aywa World',
      'url': 'https://ayworlds.com/',
      'color': Color(0xFF00695C),
      'logoUrl': 'https://cdn.files.salla.network/theme/872576583/8489e417-0114-44b4-925c-2d0c9e37fb82.webp',
    },
    {
      'id': 'qzs',
      'name': 'قمة زاوية الشفاء',
      'nameEn': 'Qimat Zawiya',
      'url': 'https://qzs-ksa.com/',
      'color': Color(0xFFB8860B),
      'logoUrl': 'https://cdn.salla.sa/wvABj/LsnsCyJ13qp3ucuFvSQy23Z6cwMJmvsSSPOFkLBv.png',
    },
    {
      'id': 'bazil',
      'name': 'بازل',
      'nameEn': 'Bazil',
      'url': 'https://bazilstore.com/',
      'color': Color(0xFF6A1B9A),
      'logoUrl': 'https://cdn.salla.sa/bZEQj/M2CunBm0fqQ8AGxEN6uXNhAMPo8RDuApey35ClJ3.png',
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
