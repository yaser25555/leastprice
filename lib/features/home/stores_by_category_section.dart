import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/data/seed/salla_affiliate_seed.dart';
import 'package:leastprice/features/home/store_offers_screen.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/features/home/popular_stores_section.dart';
import 'package:leastprice/features/home/brand_offers_section.dart';

class StoresByCategorySection extends StatelessWidget {
  const StoresByCategorySection({
    super.key,
    this.isPaid = false,
    this.onUpgradeTap,
  });

  final bool isPaid;
  final VoidCallback? onUpgradeTap;

  static const _categoryKeys = [
    'marketplaces',
    'supermarkets',
    'electronics',
    'pharmacy',
    'fashion',
    'beauty',
    'perfumes',
    'jewelry',
    'coffee',
    'home',
    'gifts',
    'sacrifice',
    'sports',
    'other',
  ];

  static const _categoryLabels = <String, Map<String, String>>{
    'marketplaces': {'ar': 'متاجر كبرى', 'en': 'Marketplaces'},
    'supermarkets': {'ar': 'سوبرماركت', 'en': 'Supermarkets'},
    'electronics': {'ar': 'إلكترونيات', 'en': 'Electronics'},
    'pharmacy': {'ar': 'صيدلية', 'en': 'Pharmacy'},
    'fashion': {'ar': 'أزياء', 'en': 'Fashion'},
    'beauty': {'ar': 'جمال وعناية', 'en': 'Beauty & Care'},
    'perfumes': {'ar': 'عطور', 'en': 'Perfumes'},
    'jewelry': {'ar': 'مجوهرات', 'en': 'Jewelry'},
    'coffee': {'ar': 'قهوة', 'en': 'Coffee'},
    'home': {'ar': 'منزل', 'en': 'Home'},
    'gifts': {'ar': 'هدايا', 'en': 'Gifts'},
    'sacrifice': {'ar': 'أضاحي', 'en': 'Sacrifice'},
    'sports': {'ar': 'رياضة', 'en': 'Sports'},
    'other': {'ar': 'أخرى', 'en': 'Other'},
  };

  static const _categoryIcons = <String, IconData>{
    'marketplaces': Icons.shopping_bag_rounded,
    'supermarkets': Icons.local_grocery_store_rounded,
    'electronics': Icons.devices_rounded,
    'pharmacy': Icons.medication_rounded,
    'fashion': Icons.checkroom_rounded,
    'beauty': Icons.face_rounded,
    'perfumes': Icons.spa_rounded,
    'jewelry': Icons.diamond_rounded,
    'coffee': Icons.coffee_rounded,
    'home': Icons.home_rounded,
    'gifts': Icons.card_giftcard_rounded,
    'sacrifice': Icons.agriculture_rounded,
    'sports': Icons.sports_soccer_rounded,
    'other': Icons.more_horiz_rounded,
  };

  static const _categoryColors = <String, Color>{
    'marketplaces': Color(0xFFFF9900),
    'supermarkets': Color(0xFF2E7D32),
    'electronics': Color(0xFF00695C),
    'pharmacy': Color(0xFF0D47A1),
    'fashion': Color(0xFFD81B60),
    'beauty': Color(0xFF9C27B0),
    'perfumes': Color(0xFF4E342E),
    'jewelry': Color(0xFFB8860B),
    'coffee': Color(0xFF6D4C41),
    'home': Color(0xFF00897B),
    'gifts': Color(0xFFE65100),
    'sacrifice': Color(0xFF2E7D32),
    'sports': Color(0xFF1A237E),
    'other': Color(0xFF607D8B),
  };

  static const _brandNameToId = <String, String>{
    'دار الاميرات': 'dar-al-amirat',
    'اضاحي كبش نجد': 'kabsh-najd',
    'ڤانير': 'vanier',
    'رشفة ذكرى': 'rashfa-dhikra',
    'روشن': 'roshen',
    'روشن تذاكر كاس العالم': 'roshen-tickets',
    'فتبول': 'futbol',
    'الريم للعبايات': 'al-reem',
    'فايب': 'vibe',
    'قطرة عسل': 'qatret-asal',
    'نايكي': 'nike',
    'H&M': 'hm',
    'سن أند ساند': 'sunsand',
    'هدى بيوتي': 'hudabeauty',
    'YSL Beauty': 'yslbeauty',
    'أندير آرمور': 'underarmour',
    'ماماز آند باباز': 'mamasandpapas',
    'بلومينغديلز': 'bloomingdales',
    'بوما': 'puma',
    'ناتشورال تاتش': 'naturaltouch',
    'نمشي': 'namshi',
  };

  static Map<String, String> get _storeCategories => {
        // متاجر كبرى
        'amazon': 'marketplaces',
        'noon': 'marketplaces',
        'namshi': 'marketplaces',
        // سوبرماركت
        'panda': 'supermarkets',
        'othaim': 'supermarkets',
        'tamimi': 'supermarkets',
        'lulu': 'supermarkets',
        'carrefour': 'supermarkets',
        // إلكترونيات
        'extra': 'electronics',
        'jarir': 'electronics',
        'threeq': 'electronics',
        'smarthub1': 'electronics',
        'alesaei': 'electronics',
        'alesaeikids': 'electronics',
        'mass': 'electronics',
        // صيدلية
        'nahdi': 'pharmacy',
        'aldawaa': 'pharmacy',
        'cuupac': 'pharmacy',
        // أزياء
        'itsmine': 'fashion',
        'alanood': 'fashion',
        'marsil': 'fashion',
        'laveen': 'fashion',
        'knoadress': 'fashion',
        'jolina': 'fashion',
        'mqueenex': 'fashion',
        'shmokfash': 'fashion',
        'starblack': 'fashion',
        'roshen': 'fashion',
        'al-reem': 'fashion',
        'almoqtas': 'fashion',
        'opera-fashion': 'fashion',
        // جمال وعناية
        'freesia': 'beauty',
        'jborgnic': 'beauty',
        'shrouqnay': 'beauty',
        'urslacare': 'beauty',
        'foryou4laser': 'beauty',
        'mlay': 'beauty',
        'retskin': 'beauty',
        'bazil': 'beauty',
        'liftglo': 'beauty',
        'vibe': 'beauty',
        'eseven': 'beauty',
        'cozmazone': 'beauty',
        'zawya-beauty': 'beauty',
        'al-ajaeb': 'beauty',
        'vion': 'beauty',
        // عطور
        'vanier': 'perfumes',
        'rashfa-dhikra': 'perfumes',
        'worldgivenchy': 'perfumes',
        'madyalteb': 'perfumes',
        'kilmananoud': 'perfumes',
        'goldenflora': 'perfumes',
        'vanilla': 'perfumes',
        // مجوهرات
        'goldlolwa': 'jewelry',
        'burgundy': 'jewelry',
        'qzs': 'jewelry',
        'bkam': 'jewelry',
        // قهوة
        'algharbi': 'coffee',
        'ragroastery': 'coffee',
        'beyyak': 'coffee',
        'parsacoffee': 'coffee',
        'swanky': 'coffee',
        'mshkatmran': 'coffee',
        // منزل
        'jawhara': 'home',
        'dunyaalasar': 'home',
        'bckyrdbbq': 'home',
        'mtjr': 'home',
        // هدايا
        'rozitaa': 'gifts',
        'takecard': 'gifts',
        'sadacards': 'gifts',
        'ayworlds': 'gifts',
        'queenarad': 'gifts',
        'hurufsa': 'gifts',
        'babybeauty': 'gifts',
        'aslalfakama': 'gifts',
        'roshen-tickets': 'gifts',
        // أضاحي
        'odhia': 'sacrifice',
        'kabsh-najd': 'sacrifice',
        'dar-al-amirat': 'sacrifice',
        'qatret-asal': 'sacrifice',
        // رياضة
        'rakla': 'sports',
        'herfitness': 'sports',
        'shaving360': 'sports',
        'trendshoesksa': 'sports',
        // أخرى
        'alhawwaj': 'other',
        'housestore': 'other',
        'futbol': 'sports',
        for (final store in SallaAffiliateSeed.stores)
          store['id'] as String: store['category'] as String,
      };

  static String _mapSeedCategory(String? cat) {
    switch (cat) {
      case 'shoes':
        return 'fashion';
      default:
        return cat ?? 'other';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupedStores() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final key in _categoryKeys) {
      groups[key] = [];
    }

    void addStore(Map<String, dynamic> store) {
      var id = store['id'] as String? ?? '';
      if (id.isEmpty) {
        final name = store['name'] as String? ?? '';
        id = _brandNameToId[name] ?? name;
      }
      final cat = _storeCategories[id] ??
          _mapSeedCategory(store['category'] as String?);
      final enriched = Map<String, dynamic>.from(store);
      enriched['id'] = id;
      groups[cat]?.add(enriched);
    }

    for (final store in PopularStoresSection.stores) {
      addStore(store);
    }

    for (final store in BrandOffersSection.stores) {
      final name = store['name'] as String? ?? '';
      final nameEn = store['nameEn'] as String? ?? '';
      final isDuplicate = PopularStoresSection.stores
          .any((s) => s['name'] == name || s['nameEn'] == nameEn);
      if (!isDuplicate) {
        addStore(store);
      }
    }

    return groups;
  }

  void _onStoreTap(BuildContext context, Map<String, dynamic> store) {
    final storeId = store['id'] as String? ?? '';
    final hasCoupon = Coupon.mockData.any((c) => c.storeId == storeId);
    final storeUrl = store['url'] as String? ?? '';

    if (hasCoupon) {
      if (!isPaid) {
        _showPaywall(context);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoreOffersScreen(
            storeId: storeId,
            storeName: store['name'] as String? ?? '',
            storeNameEn: store['nameEn'] as String? ?? '',
            storeColor: AppPalette.orange,
            storeLogoUrl: store['logoUrl'] as String?,
            storeUrl: storeUrl,
          ),
        ),
      );
    } else {
      final preparedUrl = AffiliateLinkService.prepareForOpen(storeUrl);
      launchUrl(
        Uri.parse(preparedUrl),
        mode: LaunchMode.externalApplication,
      );
    }
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final groups = _groupedStores();
    final nonEmpty = groups.entries.where((e) => e.value.isNotEmpty).toList();

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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            tr('تصفّح المتاجر مصنّفة حسب النوع', 'Browse stores by category'),
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.navy.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nonEmpty.length,
              separatorBuilder: (_, __) => Divider(
                height: 0,
                thickness: 1,
                color: AppPalette.cardBorder.withValues(alpha: 0.5),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final entry = nonEmpty[index];
                final catKey = entry.key;
                final stores = entry.value;
                final catLabel = _categoryLabels[catKey]!;
                final catIcon = _categoryIcons[catKey]!;
                final catColor = _categoryColors[catKey]!;

                return _buildCategoryTile(
                    context, catKey, catLabel, catIcon, catColor, stores);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    String catKey,
    Map<String, String> label,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> stores,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded: catKey == 'marketplaces',
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tr(label['ar']!, label['en']!),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppPalette.navy,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${stores.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppPalette.navy.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
        children: [
          _buildStoreGrid(context, stores),
        ],
      ),
    );
  }

  Widget _buildStoreGrid(
      BuildContext context, List<Map<String, dynamic>> stores) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: stores.map((store) {
            final logoUrl = store['logoUrl'] as String?;
            final name = store['name'] as String? ?? '';
            final nameEn = store['nameEn'] as String? ?? '';
            final isAldawaa = store['id'] == 'aldawaa';
            final isCarrefour = store['id'] == 'carrefour';

            return GestureDetector(
              onTap: () => _onStoreTap(context, store),
              child: SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: itemWidth,
                      height: itemWidth,
                      decoration: BoxDecoration(
                        color: isAldawaa
                            ? Colors.black.withValues(alpha: 0.05)
                            : AppPalette.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAldawaa
                              ? Colors.black.withValues(alpha: 0.15)
                              : AppPalette.orange.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Builder(builder: (context) {
                          final proxied = logoUrl != null && logoUrl.isNotEmpty
                              ? proxiedImageUrl(logoUrl)
                              : null;
                          return proxied != null && proxied.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    proxied,
                                    width: itemWidth - 16,
                                    height: itemWidth - 16,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _buildLetterBadge(name, nameEn,
                                            isAldawaa, isCarrefour),
                                  ),
                                )
                              : _buildLetterBadge(
                                  name, nameEn, isAldawaa, isCarrefour);
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(name, nameEn),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.brandNavyDeep,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildLetterBadge(
      String name, String nameEn, bool isAldawaa, bool isCarrefour) {
    final textToShow = (isCarrefour || isAldawaa)
        ? name
        : (name.isNotEmpty ? name.characters.first : '?');
    Color textColor = AppPalette.orange;
    if (isCarrefour) textColor = const Color(0xFF003087);
    if (isAldawaa) textColor = Colors.black;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isAldawaa
            ? Colors.black.withValues(alpha: 0.05)
            : AppPalette.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            textToShow,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
