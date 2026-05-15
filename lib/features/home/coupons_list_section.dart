import 'dart:async';

import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

import 'comparison_search_placeholder.dart';
import 'exclusive_coupon_card.dart';

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
          // Merge Firestore coupons with Mock data to ensure new coupons (like NDZ190) appear
          final allCoupons = [...(snapshot.data ?? const <Coupon>[]), ...Coupon.mockData];
          
          final coupons = allCoupons
              .where(
                (coupon) =>
                    coupon.active &&
                    !coupon.isExpiredAt(_now) &&
                    coupon.code.trim().isNotEmpty,
              )
              .where((coupon) {
                // Filter out obsolete stores even if they come from Firestore
                final obsoleteStores = ['iherb', 'i-herb'];
                if (obsoleteStores.contains(coupon.storeId.toLowerCase())) return false;
                
                if (_searchQuery.isEmpty) return true;
                final query = _searchQuery.toLowerCase();
                return coupon.storeName.toLowerCase().contains(query) ||
                    coupon.code.toLowerCase().contains(query) ||
                    (coupon.title?.toLowerCase().contains(query) ?? false);
              })
              .toList();

          // Deduplicate by code+storeId to avoid showing the same coupon twice if it exists in both
          final Map<String, Coupon> deduped = {};
          for (var c in coupons) {
            deduped["${c.storeId}_${c.code}"] = c;
          }
          final finalCoupons = deduped.values.toList();

          final uniqueStores = _getUniqueStores(finalCoupons);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppPalette.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(
                        '🔥 كوبونات حصرية محدثة - Build 53.2',
                        '🔥 Exclusive Updated Coupons - Build 53.2',
                      ),
                      style: TextStyle(
                        color: AppPalette.panelText,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'اختر المتجر المفضل لديك للحصول على أفضل الخصومات.',
                  'Pick your favorite store to get the best discounts.',
                ),
                style: TextStyle(
                  color: AppPalette.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Store Logos Quick Access - ALWAYS VISIBLE
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: uniqueStores.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final store = uniqueStores[index];
                    final isAldawaa =
                        (store['nameEn'] ?? '').toString().toLowerCase() ==
                            'al-dawaa';

                    return Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isAldawaa
                                ? Colors.black.withValues(alpha: 0.05)
                                : AppPalette.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isAldawaa
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : AppPalette.orange.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: _buildStoreLogo(store),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),
              ),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: tr('ابحث عن متجر أو كود خصم...', 'Search for a store or code...'),
                  prefixIcon: Icon(Icons.search_rounded, color: AppPalette.orange),
                  filled: true,
                  fillColor: AppPalette.orange.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppPalette.orange.withValues(alpha: 0.4), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Categorized Grid
              if (activeCategories.isEmpty)
                const Center(child: ComparisonSearchPlaceholder())
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = activeCategories[index];
                    final catKey = entry.key;
                    final categoryCoupons = entry.value;
                    
                    return _buildCategorySection(catKey, categoryCoupons);
                  },
                ),
                
              const SizedBox(height: 20),
              // Debug build indicator in footer
              Center(
                child: Text(
                  "Build v53.2.1 Sync",
                  style: TextStyle(
                    color: AppPalette.orange.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getStoreCategory(String storeId) {
    // Map store IDs to categories (can be expanded)
    final map = {
      'amazon': 'marketplaces', 'noon': 'marketplaces', 'namshi': 'marketplaces',
      'panda': 'supermarkets', 'othaim': 'supermarkets', 'tamimi': 'supermarkets',
      'nahdi': 'pharmacy', 'aldawaa': 'pharmacy',
      'itsmine': 'fashion', 'alanood': 'fashion', 'marsil': 'fashion', 'laveen': 'fashion',
      'freesia': 'beauty', 'jborgnic': 'beauty', 'mlay': 'beauty',
      'vanier': 'perfumes', 'rashfa-dhikra': 'perfumes',
      'extra': 'electronics', 'jarir': 'electronics',
    };
    return map[storeId.toLowerCase()] ?? 'other';
  }

  Widget _buildCategorySection(String catKey, List<Coupon> categoryCoupons) {
    // Group coupons by store within the category for a cleaner grid
    final Map<String, List<Coupon>> storeGroups = {};
    for (var c in categoryCoupons) {
      storeGroups[c.storeId] = (storeGroups[c.storeId] ?? [])..add(c);
    }

    final categoryLabel = _getCategoryLabel(catKey);
    final categoryIcon = _getCategoryIcon(catKey);
    final categoryColor = _getCategoryColor(catKey);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.navy.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categoryIcon, color: categoryColor, size: 20),
        ),
        title: Text(
          categoryLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppPalette.navy),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: storeGroups.entries.map((group) {
                final firstCoupon = group.value.first;
                return _buildStoreCouponCard(firstCoupon, group.value.length);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCouponCard(Coupon coupon, int count) {
    return GestureDetector(
      onTap: () {
        _showStoreCoupons(coupon.storeId, coupon.storeName);
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppPalette.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppPalette.orange.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Center(
                child: _buildStoreLogo(coupon, 44),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              coupon.storeName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppPalette.navy),
            ),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppPalette.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreLogo(Coupon coupon, double size) {
    final logoUrl = coupon.storeLogoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildLetterFallback(coupon.storeName, size),
        ),
      );
    }
    return _buildLetterFallback(coupon.storeName, size);
  }

  Widget _buildLetterFallback(String name, double size) {
    return Text(
      name.isNotEmpty ? name.characters.first : '?',
      style: TextStyle(color: AppPalette.orange, fontWeight: FontWeight.w900, fontSize: size * 0.5),
    );
  }

  void _showStoreCoupons(String storeId, String storeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr("عرض كوبونات $storeName", "Showing coupons for $storeName")))
    );
  }

  String _getCategoryLabel(String key) {
    final labels = {
      'marketplaces': 'متاجر كبرى', 'fashion': 'أزياء', 'beauty': 'جمال وعناية',
      'electronics': 'إلكترونيات', 'supermarkets': 'سوبرماركت', 'pharmacy': 'صيدلية',
      'perfumes': 'عطور', 'jewelry': 'مجوهرات', 'coffee': 'قهوة', 'home': 'منزل',
      'gifts': 'هدايا', 'sacrifice': 'أضاحي', 'sports': 'رياضة', 'other': 'أخرى'
    };
    return labels[key] ?? 'أخرى';
  }

  IconData _getCategoryIcon(String key) {
    final icons = {
      'marketplaces': Icons.shopping_bag_rounded, 'fashion': Icons.checkroom_rounded,
      'beauty': Icons.face_rounded, 'electronics': Icons.devices_rounded,
      'supermarkets': Icons.local_grocery_store_rounded, 'pharmacy': Icons.medication_rounded,
      'perfumes': Icons.spa_rounded, 'jewelry': Icons.diamond_rounded,
      'coffee': Icons.coffee_rounded, 'home': Icons.home_rounded,
      'gifts': Icons.card_giftcard_rounded, 'sacrifice': Icons.agriculture_rounded,
      'sports': Icons.sports_soccer_rounded, 'other': Icons.more_horiz_rounded
    };
    return icons[key] ?? Icons.category_rounded;
  }

  Color _getCategoryColor(String key) {
    final colors = {
      'marketplaces': const Color(0xFFFF9900), 'fashion': const Color(0xFFD81B60),
      'beauty': const Color(0xFF9C27B0), 'electronics': const Color(0xFF00695C),
      'supermarkets': const Color(0xFF2E7D32), 'pharmacy': const Color(0xFF0D47A1),
      'perfumes': const Color(0xFF4E342E), 'jewelry': const Color(0xFFB8860B),
      'coffee': const Color(0xFF6D4C41), 'home': const Color(0xFF00897B),
      'gifts': const Color(0xFFE65100), 'sacrifice': const Color(0xFF2E7D32),
      'sports': const Color(0xFF1A237E), 'other': const Color(0xFF607D8B)
    };
    return colors[key] ?? Colors.grey;
  }

  List<Map<String, dynamic>> _getUniqueStores(List<Coupon> coupons) {
    // Primary application stores (Major retailers)
    final List<Map<String, dynamic>> appStores = [
      {
        'name': 'نون',
        'nameEn': 'Noon',
        'logoUrl': 'https://icon.horse/icon/noon.com'
      },
      {
        'name': 'أمازون',
        'nameEn': 'Amazon',
        'logoUrl': 'https://icon.horse/icon/amazon.sa'
      },
      {
        'name': 'نمشي',
        'nameEn': 'Namshi',
        'logoUrl': 'https://icon.horse/icon/namshi.com'
      },
      {
        'name': 'سيـفورا',
        'nameEn': 'Sephora',
        'logoUrl': 'https://icon.horse/icon/sephora.com'
      },
    ];

    final Map<String, Map<String, dynamic>> seen = {};

    // 1. Add stores that currently have active coupons (Prioritize them)
    for (var c in coupons) {
      final name = c.storeName;
      if (!seen.containsKey(name)) {
        seen[name] = {
          'name': name,
          'nameEn': name,
          'logoUrl': (c.storeLogoUrl ?? '').trim().isNotEmpty
              ? c.storeLogoUrl!.trim()
              : resolveStoreLogoUrl(
                  storeId: c.storeId,
                  productUrl: c.storeUrl ?? '',
                  fallbackName: name,
                ),
        };
      }
    }

    // 2. Fill in with other major application stores
    for (var s in appStores) {
      if (!seen.containsKey(s['name'])) {
        seen[s['name']] = s;
      }
    }

    return seen.values.toList();
  }

  Widget _buildStoreLogo(Map<String, dynamic> store) {
    final logoUrl = store['logoUrl'] as String? ?? '';
    final name = store['name'] as String;
    final nameEn = (store['nameEn'] as String).toLowerCase();

    final isAldawaa = nameEn == 'al-dawaa';
    final isCarrefour = nameEn == 'carrefour';

    if (logoUrl.isNotEmpty && !isAldawaa && !isCarrefour) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          proxiedImageUrl(logoUrl),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildTextFallback(name, nameEn),
        ),
      );
    }

    return _buildTextFallback(name, nameEn);
  }

  Widget _buildTextFallback(String name, String nameEn) {
    final isCarrefour = nameEn == 'carrefour';
    final isAldawaa = nameEn == 'al-dawaa';

    final text = (isCarrefour || isAldawaa)
        ? name
        : (name.isNotEmpty ? name.characters.first : '?');

    Color textColor = AppPalette.orange;
    if (isCarrefour) textColor = const Color(0xFF003087);
    if (isAldawaa) textColor = Colors.black;

    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: (isCarrefour || isAldawaa) ? 11 : 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
