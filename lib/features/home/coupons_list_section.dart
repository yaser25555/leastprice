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
          // Merge Firestore coupons with Mock data
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
                // Filter out obsolete stores
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

          // Deduplicate by code+storeId
          final Map<String, Coupon> deduped = {};
          for (var c in coupons) {
            deduped['${c.storeId}_${c.code}'] = c;
          }
          final finalCoupons = deduped.values.toList();

          // Group coupons by category
          final Map<String, List<Coupon>> grouped = {};
          const categories = [
            'marketplaces', 'fashion', 'beauty', 'electronics',
            'supermarkets', 'pharmacy', 'perfumes', 'jewelry',
            'coffee', 'home', 'gifts', 'sacrifice', 'sports', 'other',
          ];

          for (var cat in categories) {
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
              // ── Header ──
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppPalette.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(
                        '🔥 كوبونات حصرية محدثة',
                        '🔥 Exclusive Updated Coupons',
                      ),
                      style: TextStyle(
                        color: AppPalette.panelText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'اختر التصنيف للحصول على أفضل الخصومات.',
                  'Pick a category to get the best discounts.',
                ),
                style: TextStyle(
                  color: AppPalette.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ── Search Bar ──
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: tr(
                    'ابحث عن متجر أو كود خصم...',
                    'Search for a store or code...',
                  ),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: AppPalette.orange),
                  filled: true,
                  fillColor: AppPalette.orange.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppPalette.orange.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // ── Categorized Grid ──
              if (activeCategories.isEmpty)
                ComparisonSearchPlaceholder(
                  title: tr(
                    'لا توجد كوبونات نشطة حالياً.',
                    'No active coupons right now.',
                  ),
                  icon: Icons.local_offer_outlined,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = activeCategories[index];
                    return _buildCategorySection(
                        entry.key, entry.value);
                  },
                ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Build v53.3',
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

  // ─────────────────────────────────────────────────────
  // Category helpers
  // ─────────────────────────────────────────────────────

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

  String _getCategoryLabel(String key) {
    final labels = {
      'marketplaces': tr('متاجر كبرى', 'Marketplaces'),
      'fashion': tr('أزياء', 'Fashion'),
      'beauty': tr('جمال وعناية', 'Beauty'),
      'electronics': tr('إلكترونيات', 'Electronics'),
      'supermarkets': tr('سوبرماركت', 'Supermarkets'),
      'pharmacy': tr('صيدلية', 'Pharmacy'),
      'perfumes': tr('عطور', 'Perfumes'),
      'jewelry': tr('مجوهرات وإكسسوارات', 'Jewelry & Accessories'),
      'coffee': tr('قهوة', 'Coffee'),
      'home': tr('منزل', 'Home'),
      'gifts': tr('هدايا وتذاكر', 'Gifts & Tickets'),
      'sacrifice': tr('أضاحي', 'Sacrifice'),
      'sports': tr('رياضة', 'Sports'),
      'other': tr('أخرى', 'Other'),
    };
    return labels[key] ?? tr('أخرى', 'Other');
  }

  IconData _getCategoryIcon(String key) {
    const icons = {
      'marketplaces': Icons.shopping_bag_rounded,
      'fashion': Icons.checkroom_rounded,
      'beauty': Icons.face_rounded,
      'electronics': Icons.devices_rounded,
      'supermarkets': Icons.local_grocery_store_rounded,
      'pharmacy': Icons.medication_rounded,
      'perfumes': Icons.spa_rounded,
      'jewelry': Icons.diamond_rounded,
      'coffee': Icons.coffee_rounded,
      'home': Icons.home_rounded,
      'gifts': Icons.card_giftcard_rounded,
      'sacrifice': Icons.agriculture_rounded,
      'sports': Icons.sports_soccer_rounded,
      'other': Icons.more_horiz_rounded,
    };
    return icons[key] ?? Icons.category_rounded;
  }

  Color _getCategoryColor(String key) {
    const colors = {
      'marketplaces': Color(0xFFFF9900),
      'fashion': Color(0xFFD81B60),
      'beauty': Color(0xFF9C27B0),
      'electronics': Color(0xFF00695C),
      'supermarkets': Color(0xFF2E7D32),
      'pharmacy': Color(0xFF0D47A1),
      'perfumes': Color(0xFF4E342E),
      'jewelry': Color(0xFFB8860B),
      'coffee': Color(0xFF6D4C41),
      'home': Color(0xFF00897B),
      'gifts': Color(0xFFE65100),
      'sacrifice': Color(0xFF2E7D32),
      'sports': Color(0xFF1A237E),
      'other': Color(0xFF607D8B),
    };
    return colors[key] ?? Colors.grey;
  }

  // ─────────────────────────────────────────────────────
  // Category section builder
  // ─────────────────────────────────────────────────────

  Widget _buildCategorySection(String catKey, List<Coupon> categoryCoupons) {
    final Map<String, List<Coupon>> storeGroups = {};
    for (var c in categoryCoupons) {
      (storeGroups[c.storeId] ??= []).add(c);
    }

    final categoryLabel = _getCategoryLabel(catKey);
    final categoryIcon = _getCategoryIcon(catKey);
    final categoryColor = _getCategoryColor(catKey);

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          title: Text(
            categoryLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppPalette.panelText,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 14,
                children: storeGroups.entries.map((group) {
                  final firstCoupon = group.value.first;
                  return _buildStoreCouponCard(
                      firstCoupon, group.value.length);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Store coupon card (small icon grid item)
  // ─────────────────────────────────────────────────────

  Widget _buildStoreCouponCard(Coupon coupon, int count) {
    return GestureDetector(
      onTap: () => widget.onCopyCoupon(coupon.code),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppPalette.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppPalette.orange.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: _buildCouponStoreLogo(coupon, 40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              coupon.storeName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppPalette.panelText,
              ),
            ),
            if (count > 1)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppPalette.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Logo builder for coupons
  // ─────────────────────────────────────────────────────

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
        fontSize: size * 0.5,
      ),
    );
  }
}
