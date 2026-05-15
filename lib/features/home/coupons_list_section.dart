import 'dart:async';

import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

import 'comparison_search_placeholder.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: StreamBuilder<List<Coupon>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          final allCoupons = [
            ...(snapshot.data ?? const <Coupon>[]),
            ...Coupon.mockData,
          ];

          final coupons = allCoupons
              .where(
                (coupon) =>
                    coupon.active &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.code.trim().isNotEmpty,
              )
              .where((coupon) {
                const obsoleteStores = ['iherb', 'i-herb'];
                if (obsoleteStores.contains(coupon.storeId.toLowerCase())) {
                  return false;
                }
                if (_searchQuery.isEmpty) return true;
                final query = _searchQuery.toLowerCase();
                return coupon.storeName.toLowerCase().contains(query) ||
                    coupon.code.toLowerCase().contains(query) ||
                    (coupon.title?.toLowerCase().contains(query) ?? false);
              })
              .toList();

          final Map<String, Coupon> deduped = {};
          for (var c in coupons) {
            deduped['${c.storeId}_${c.code}'] = c;
          }
          final finalCoupons = deduped.values.toList();

          final Map<String, List<Coupon>> grouped = {};
          for (var cat in _categoryKeys) {
            grouped[cat] = [];
          }

          for (var c in finalCoupons) {
            final cat = _getStoreCategory(c.storeId);
            (grouped[cat] ??= []).add(c);
          }

          final activeCategories =
              grouped.entries.where((e) => e.value.isNotEmpty).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              if (activeCategories.isEmpty)
                ComparisonSearchPlaceholder(
                  title: tr(
                    'لا توجد كوبونات نشطة حالياً.',
                    'No active coupons right now.',
                  ),
                  icon: Icons.local_offer_outlined,
                )
              else
                _buildCategoryList(activeCategories),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppPalette.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.confirmation_number_rounded,
            color: AppPalette.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('كوبونات حصرية', 'Exclusive Coupons'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tr(
                  'اختر التصنيف للحصول على أفضل الخصومات',
                  'Pick a category to get the best discounts',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: AppPalette.navy.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: tr(
            'ابحث عن متجر أو كود خصم...',
            'Search for a store or code...',
          ),
          prefixIcon: Icon(Icons.search_rounded, color: AppPalette.orange),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<MapEntry<String, List<Coupon>>> categories) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Divider(
          height: 0,
          thickness: 1,
          color: AppPalette.cardBorder.withValues(alpha: 0.5),
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          final entry = categories[index];
          return _buildCategoryTile(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildCategoryTile(String catKey, List<Coupon> coupons) {
    final Map<String, List<Coupon>> storeGroups = {};
    for (var c in coupons) {
      (storeGroups[c.storeId] ??= []).add(c);
    }

    final catColor = _categoryColors[catKey] ?? AppPalette.orange;
    final catIcon = _categoryIcons[catKey] ?? Icons.category_rounded;
    final label = _categoryLabels[catKey]!;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            color: catColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(catIcon, color: catColor, size: 20),
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
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${storeGroups.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: catColor,
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
          _buildCouponGrid(storeGroups),
        ],
      ),
    );
  }

  Widget _buildCouponGrid(Map<String, List<Coupon>> storeGroups) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: storeGroups.entries.map((group) {
            final firstCoupon = group.value.first;
            final count = group.value.length;
            return GestureDetector(
              onTap: () => widget.onCopyCoupon(firstCoupon.code),
              child: SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: itemWidth,
                      height: itemWidth,
                      decoration: BoxDecoration(
                        color: AppPalette.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppPalette.orange.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: _buildCouponStoreLogo(firstCoupon, itemWidth - 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      firstCoupon.storeName,
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppPalette.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        count > 1
                            ? '$count ${tr('كوبونات', 'coupons')}'
                            : firstCoupon.code,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppPalette.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _buildCouponStoreLogo(Coupon coupon, double size) {
    final logoUrl = coupon.storeLogoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _buildLetterFallback(coupon.storeName, size),
        ),
      );
    }
    return _buildLetterFallback(coupon.storeName, size);
  }

  Widget _buildLetterFallback(String name, double size) {
    return Text(
      name.isNotEmpty ? name.characters.first : '?',
      style: TextStyle(
        color: AppPalette.orange,
        fontWeight: FontWeight.w900,
        fontSize: size * 0.45,
      ),
    );
  }

  String _getStoreCategory(String storeId) {
    const map = {
      'amazon': 'marketplaces',
      'noon': 'marketplaces',
      'namshi': 'marketplaces',
      'shein': 'fashion',
      'itsmine': 'fashion',
      'alanood': 'fashion',
      'al-reem': 'fashion',
      'roshen': 'fashion',
      'sephora': 'beauty',
      'vanier': 'perfumes',
      'rashfa-dhikra': 'perfumes',
      'extra': 'electronics',
      'jarir': 'electronics',
      'panda': 'supermarkets',
      'othaim': 'supermarkets',
      'tamimi': 'supermarkets',
      'lulu': 'supermarkets',
      'carrefour': 'supermarkets',
      'nahdi': 'pharmacy',
      'aldawaa': 'pharmacy',
      'kabsh-najd': 'sacrifice',
      'roshen-tickets': 'gifts',
      'vibe': 'jewelry',
    };
    return map[storeId.toLowerCase()] ?? 'other';
  }
}
