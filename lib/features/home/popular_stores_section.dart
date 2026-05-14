import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/data/seed/salla_affiliate_seed.dart';
import 'package:leastprice/features/home/store_offers_screen.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';

class PopularStoresSection extends StatelessWidget {
  const PopularStoresSection({
    super.key,
    this.isPaid = false,
    this.onUpgradeTap,
  });

  final bool isPaid;
  final VoidCallback? onUpgradeTap;

  static const Color _catColorFashion = Color(0xFFD81B60);
  static const Color _catColorBeauty = Color(0xFF9C27B0);
  static const Color _catColorElectronics = Color(0xFF00695C);
  static const Color _catColorJewelry = Color(0xFFB8860B);
  static const Color _catColorShoes = Color(0xFF1A237E);
  static const Color _catColorOther = Color(0xFF607D8B);

  static Color _colorForCategory(String cat) {
    switch (cat) {
      case 'fashion':
        return _catColorFashion;
      case 'beauty':
        return _catColorBeauty;
      case 'electronics':
        return _catColorElectronics;
      case 'jewelry':
        return _catColorJewelry;
      case 'shoes':
      case 'sports':
        return _catColorShoes;
      default:
        return _catColorOther;
    }
  }

  static List<Map<String, dynamic>> get stores {
    final seedStores = SallaAffiliateSeed.stores.map((s) => {
          'id': s['id'] as String? ?? '',
          'name': s['name'] as String? ?? '',
          'nameEn': s['nameEn'] as String? ?? '',
          'url': s['url'] as String? ?? '',
          'color': _colorForCategory(s['category'] as String? ?? 'other'),
          'logoUrl': s['logoUrl'] as String? ?? '',
        });
    return [..._manualStores, ...seedStores];
  }

  static const List<Map<String, dynamic>> _manualStores = [
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
    {
      'id': 'odhia',
      'name': 'أضحية',
      'nameEn': 'Odhia',
      'url': 'https://odhia.co/',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://cdn.salla.sa/ZYqAQY/oS44KrQChZxdGQ0Iqd5faOage8eH4vlQe1VUo8vo.png',
    },
    {
      'id': 'jawhara',
      'name': 'جوهره أونلاين',
      'nameEn': 'Jawhara Online',
      'url': 'https://jawhara.online/',
      'color': Color(0xFFB8860B),
      'logoUrl': 'https://cdn.salla.sa/ydAVda/BK5s47EMDHPkWIsnAyRCvwEGS0aPfBxLApnGBJh7.png',
    },
    {
      'id': 'knoadress',
      'name': 'knoadress',
      'nameEn': 'KNO A Dress',
      'url': 'https://knoadress.com/',
      'color': Color(0xFFD4A5C4),
      'logoUrl': 'https://cdn.salla.sa/qjNzO/w1u09cVvL5NKd8Ai93u9lrCH1yr24ujxAtHkUQGI.jpg',
    },
    {
      'id': 'babybeauty',
      'name': 'بوتيك بيبي بيوتي',
      'nameEn': 'Baby Beauty Boutique',
      'url': 'https://babybeautyksa.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.salla.sa/NGKEy/k5yRkshCjLgmy0YoSHwGmuaYamoYL2Zjje5ZpRSr.png',
    },
    {
      'id': 'jolina',
      'name': 'جولينا',
      'nameEn': 'Jolina Fashion',
      'url': 'https://jolinafashion.com/',
      'color': Color(0xFF9C27B0),
      'logoUrl': 'https://cdn.salla.sa/GgXea/bUMkk5HhVztx5GkFkwvxpR3pvep6Yr74boQfwSHf.png',
    },
    {
      'id': 'mqueenex',
      'name': 'كيونكس',
      'nameEn': 'M Queenex',
      'url': 'https://mqueenex.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://cdn.salla.sa/lGZAVr/Tm1JpEGA5bmbY2s2J1R9L2bj6LwrAcfttOABWyXT.png',
    },
    {
      'id': 'beyyak',
      'name': 'بياك',
      'nameEn': 'Beyyak',
      'url': 'https://beyyak.com/',
      'color': Color(0xFF6D4C41),
      'logoUrl': 'https://cdn.salla.sa/mEGGZ/RSAfOBm0aCa9rcBKe4oilKxNYWvLU5Qt0dphgyv7.png',
    },
    {
      'id': 'aslalfakama',
      'name': 'أصل الفخامة',
      'nameEn': 'Asl Al Fakama',
      'url': 'https://aslalfakama.com/',
      'color': Color(0xFFD4AF37),
      'logoUrl': 'https://cdn.salla.sa/XoKyj/ny4iz11g0PJxiR4iMkXTz6jFWHUYyymKYFrjVXym.png',
    },
    {
      'id': 'rozitaa',
      'name': 'روزيتا',
      'nameEn': 'Rozitaa',
      'url': 'https://rozitaa.com/',
      'color': Color(0xFFD81B60),
      'logoUrl': 'https://cdn.salla.sa/rAezWw/nMPpJt9EnlI3pJWtVfxKhZwqympUm87S6WR5ozFc.png',
    },
    {
      'id': 'foryou4laser',
      'name': 'فور يو',
      'nameEn': 'For You',
      'url': 'https://mlay2022s.com/',
      'color': Color(0xFFEC407A),
      'logoUrl': 'https://cdn.salla.sa/ZBlnZ/OVXxxRHLLph6DyobrLdAcFYJ5FhZIlJWSxHoBpgR.jpg',
    },
    {
      'id': 'cuupac',
      'name': 'Cuupac',
      'nameEn': 'Cuupac',
      'url': 'https://cuupac.com/',
      'color': Color(0xFF26A69A),
      'logoUrl': 'https://cdn.salla.sa/OZOyo/Mc2rFRqmDrIgX3aT9OHIzggj1GIUMbjxkSFjxOQc.png',
    },
    {
      'id': 'jborgnic',
      'name': 'جي بي اورجانيك',
      'nameEn': 'JB Organic',
      'url': 'https://jb.sa/',
      'color': Color(0xFF4CAF50),
      'logoUrl': 'https://cdn.salla.sa/xAyjrK/E6nZawyHfTnuqtZen3eWk0fqHloGFXlwdyd43KSH.png',
    },
    {
      'id': 'alesaei',
      'name': 'العيسائي للإلكترونيات',
      'nameEn': 'Al-Esaei Electronics',
      'url': 'https://aecksa.com/',
      'color': Color(0xFF1565C0),
      'logoUrl': 'https://cdn.salla.sa/wWRQaK/1u3M49PZ7XXc2RXTFZHBpF40gs8jtqT4jUxRA7hE.png',
    },
    {
      'id': 'hurufsa',
      'name': 'تطريز',
      'nameEn': 'Tatreez',
      'url': 'https://hurufsa.com/',
      'color': Color(0xFF7B1FA2),
      'logoUrl': 'https://cdn.salla.sa/aZqED/xmdP3KkSYTkhyJGCmBx56HVi6maRu09VahbqyRU2.jpg',
    },
    {
      'id': 'urslacare',
      'name': 'اورسلا كير',
      'nameEn': 'Ursla Care',
      'url': 'https://urslacare.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.salla.sa/AxwjD/JQI4zlZpdQUu4fxyJLIVsxj7X6ZSbNznNSCwFBFf.png',
    },
    {
      'id': 'parsacoffee',
      'name': 'بارسا كافيه',
      'nameEn': 'Parsa Coffee',
      'url': 'https://parsacoffee.com/',
      'color': Color(0xFF5D4037),
      'logoUrl': 'https://cdn.salla.sa/ZYlZNn/t6EYphOXtm6CHC7sU9yjwsJHl9EF61xp70wuNf5A.jpg',
    },
    {
      'id': 'shrouqnay',
      'name': 'شروق ناي',
      'nameEn': 'Shrouq Nay',
      'url': 'https://shrouqnay.com/',
      'color': Color(0xFF9C27B0),
      'logoUrl': 'https://cdn.salla.sa/bGbrj/jEV8rGpz35sXUdYZtUo49ovVybPXzbz8e70t5BUW.png',
    },
    {
      'id': 'liftglo',
      'name': 'LiftGlo',
      'nameEn': 'LiftGlo',
      'url': 'https://liftgloksa.com/',
      'color': Color(0xFF00BCD4),
      'logoUrl': 'https://cdn.salla.sa/zvwQGR/DSchqtRa409p3g4eRnKzgUQhJ6OQzqr2vUtnYj99.png',
    },
    {
      'id': 'shmokfash',
      'name': 'شموخ',
      'nameEn': 'Shmokh Fashion',
      'url': 'https://shmokfash.com/',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.salla.sa/PVemn/CCHTEp44vR23iEzRc32ILGZIj8VeYN4QXuyQ98vU.jpg',
    },
    {
      'id': 'starblack',
      'name': 'ستار بلاك',
      'nameEn': 'Star Black',
      'url': 'https://star-black.com/',
      'color': Color(0xFF212121),
      'logoUrl': 'https://cdn.salla.sa/XyApj/vOVHx99IMSxkJ8XKDTkJvO7snYGmxJH9JlYN7v92.jpg',
    },
    {
      'id': 'dunyaalasar',
      'name': 'دنيا الاسعار',
      'nameEn': 'Dunya Al Asar',
      'url': 'https://dunya-alasar.sa/',
      'color': Color(0xFF00897B),
      'logoUrl': 'https://cdn.salla.sa/gZPwmV/QnlbMCzERqXpHzH8VjR0zgXf4lzEdwIQuCVwGgu1.png',
    },
    {
      'id': 'queenarad',
      'name': 'Queen Arab',
      'nameEn': 'Queen Arab',
      'url': 'https://queenarad.com/',
      'color': Color(0xFFFF6F00),
      'logoUrl': 'https://cdn.salla.sa/XDEDY/6kjyvTPkj954PVRaziRg7HCeBZfmY6unEYi9t2Df.png',
    },
    {
      'id': 'alesaeikids',
      'name': 'العيسائي للأطفال',
      'nameEn': 'Al-Esaei Kids',
      'url': 'https://alesaei-aes.com/',
      'color': Color(0xFF42A5F5),
      'logoUrl': 'https://cdn.salla.sa/zvpXyK/z7xwXndn4InrwGVrfb1FVcnk0MINaPBX8wqhp0yC.png',
    },
    {
      'id': 'goldenflora',
      'name': 'قولدن فلورا',
      'nameEn': 'Golden Flora',
      'url': 'https://golden-flora.com/',
      'color': Color(0xFFD4AF37),
      'logoUrl': 'https://cdn.files.salla.network/theme/1526962400/a611630a-8bee-48f4-83e3-5862e881eb16.webp',
    },
    {
      'id': 'zawya-beauty',
      'name': 'زاوية التجميل',
      'nameEn': 'Zawya Beauty',
      'url': 'https://mtjr.at/h17sGc_J_I',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.files.salla.network/theme/875954336/c95597e4-0c18-429d-ad44-f04ce1beb59b.webp',
    },
    {
      'id': 'vanilla',
      'name': 'فانيلا',
      'nameEn': 'Vanilla',
      'url': 'https://mtjr.at/bAqdtL0fsC',
      'color': Color(0xFF7B1FA2),
      'logoUrl': 'https://cdn.salla.sa/dqYz/29gFymuetLC5kPRrb6sk8lRPgDZlryKYf41dWCig.jpg',
    },
    {
      'id': 'al-ajaeb',
      'name': 'العجائب',
      'nameEn': 'Al-Ajaeb',
      'url': 'https://mtjr.at/nQjQwehVEG',
      'color': Color(0xFF2E7D32),
      'logoUrl': 'https://cdn.salla.sa/KPpXD/TA15bFHSZccw26t8zbknGC2Pe7xGZLaM6PzTAMZ6.png',
    },
    {
      'id': 'vion',
      'name': 'VION',
      'nameEn': 'VION',
      'url': 'https://mtjr.at/4mulF6oPTP',
      'color': Color(0xFFE91E63),
      'logoUrl': 'https://cdn.salla.sa/rNlBj/xGCxVYK42nlshUzuXi3WIwzlA8VL9zAt8KwNTEiH.png',
    },
    {
      'id': 'trendshoesksa',
      'name': 'تريند شوز',
      'nameEn': 'TrendShoesKSA',
      'url': 'https://mtjr.at/s-vty423A4',
      'color': Color(0xFFFF5722),
      'logoUrl': 'https://cdn.files.salla.network/theme/269331473/b088bf07-f65c-4da2-b7fa-23114bfdd363.webp',
    },
    {
      'id': 'mass',
      'name': 'متجر ماس',
      'nameEn': 'MASS',
      'url': 'https://mtjr.at/RWAJpS5n1w',
      'color': Color(0xFF9C27B0),
      'logoUrl': 'https://cdn.salla.sa/QvEwN/IKzQdOnMvdXCUhuy3H1bHVr4JNZd27XD9O1OZaUy.png',
    },
    {
      'id': 'opera-fashion',
      'name': 'أوبرا فاشن',
      'nameEn': 'Opera Fashion',
      'url': 'https://mtjr.at/WLpQYiflLI',
      'color': Color(0xFF009688),
      'logoUrl': 'https://cdn.salla.sa/KAdxD/JuCPlNIPeTa7CrMAT9iEymyovtynpJ77XHufOAZd.png',
    },
    {
      'id': 'housestore',
      'name': 'HOUSE STORE',
      'nameEn': 'HOUSE STORE',
      'url': 'https://mtjr.at/RxE9m4Ge6L',
      'color': Color(0xFF795548),
      'logoUrl': 'https://cdn.salla.sa/onpDqX/YVEN4bsU5bv7so4sSGkUcyn0FV2tp67Az1O4VprY.png',
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
                  final storeId = store['id'] as String;
                  final hasCoupon = Coupon.mockData
                      .any((c) => c.storeId == storeId);
                  final storeUrl = store['url'] as String;

                  if (hasCoupon) {
                    if (!isPaid) {
                      _showPaywall(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreOffersScreen(
                          storeId: storeId,
                          storeName: store['name'],
                          storeNameEn: store['nameEn'],
                          storeColor: AppPalette.orange,
                          storeLogoUrl: logoUrl,
                          storeUrl: storeUrl,
                        ),
                      ),
                    );
                  } else {
                    final preparedUrl =
                        AffiliateLinkService.prepareForOpen(storeUrl);
                    launchUrl(
                      Uri.parse(preparedUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
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

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: AppPalette.orange, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tr('ميزة مدفوعة', 'Premium feature'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          tr(
            'هذا المتجر يتطلب اشتراكاً مدفوعاً لعرض الكوبونات الحصرية. اشترك الآن واحصل على خصومات مذهلة!',
            'This store requires a paid subscription to view exclusive coupons. Subscribe now and get amazing discounts!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('رجوع', 'Back'),
              style: TextStyle(color: AppPalette.navy),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpgradeTap?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.orange,
              foregroundColor: AppPalette.pureWhite,
            ),
            child: Text(tr('اشترك الآن', 'Subscribe now')),
          ),
        ],
      ),
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
