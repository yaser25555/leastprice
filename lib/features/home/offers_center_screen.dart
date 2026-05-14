import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/seed/salla_affiliate_seed.dart';
import 'package:leastprice/features/home/brand_offers_section.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OffersCenterScreen extends StatefulWidget {
  const OffersCenterScreen({super.key});

  @override
  State<OffersCenterScreen> createState() => _OffersCenterScreenState();
}

class _OffersCenterScreenState extends State<OffersCenterScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'الكل', 'nameEn': 'All', 'icon': Icons.grid_view_rounded},
    {'id': 'women', 'name': 'المرأة واهتماماتها', 'nameEn': 'Women & Interests', 'icon': Icons.woman_rounded},
    {'id': 'electronics', 'name': 'إلكترونيات', 'nameEn': 'Electronics', 'icon': Icons.devices_rounded},
    {'id': 'shopping', 'name': 'تسوق عام', 'nameEn': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'id': 'gaming', 'name': 'ألعاب وبطاقات', 'nameEn': 'Gaming & Cards', 'icon': Icons.sports_esports_rounded},
    {'id': 'home', 'name': 'المنزل', 'nameEn': 'Home', 'icon': Icons.home_rounded},
  ];

  List<Map<String, dynamic>> get _allStores {
    // Combine hardcoded stores from BrandOffersSection and SallaAffiliateSeed
    final List<Map<String, dynamic>> combined = [];
    
    // Add main brands from section
    combined.addAll(BrandOffersSection.stores.map((s) => {...s, 'source': 'main'}));
    
    // Add salla stores
    combined.addAll(SallaAffiliateSeed.stores.map((s) => {
      'id': s['id'],
      'name': s['name'],
      'nameEn': s['nameEn'],
      'url': s['url'],
      'logoUrl': s['logoUrl'],
      'category': s['category'],
      'hasCoupon': ((s['couponCode'] as String?)?.trim().isNotEmpty ?? false),
      'source': 'salla',
    }));

    return combined;
  }

  List<Map<String, dynamic>> get _filteredStores {
    return _allStores.where((store) {
      final name = (store['name'] as String).toLowerCase();
      final nameEn = (store['nameEn'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      final matchesSearch = name.contains(query) || nameEn.contains(query);
      
      if (!matchesSearch) return false;
      if (_selectedCategory == 'all') return true;
      
      final cat = store['category'] as String?;
      if (_selectedCategory == 'women') {
        return ['fashion', 'beauty', 'jewelry', 'shoes'].contains(cat);
      }
      if (_selectedCategory == 'electronics') {
        return cat == 'electronics';
      }
      if (_selectedCategory == 'shopping') {
        return ['amazon', 'noon', 'supermarkets'].contains(cat) || store['source'] == 'main';
      }
      // Default to other categories or uncategorized
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.turquoise.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildSearchAndFilters(),
            _buildStoreGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppPalette.navy,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          tr('مركز العروض', 'Offers Center'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        background: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPalette.navy, AppPalette.navy.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.navy.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: tr('ابحث عن متجر...', 'Search for a store...'),
                  prefixIcon: Icon(Icons.search_rounded, color: AppPalette.orange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          // Categories
          SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: FilterChip(
                    label: Text(tr(cat['name'], cat['nameEn'])),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedCategory = cat['id']),
                    backgroundColor: Colors.white,
                    selectedColor: AppPalette.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppPalette.navy,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    avatar: Icon(
                      cat['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : AppPalette.orange,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppPalette.orange : AppPalette.navy.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGrid() {
    final stores = _filteredStores;
    if (stores.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: AppPalette.navy.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                tr('لا توجد نتائج بحث', 'No stores found'),
                style: TextStyle(color: AppPalette.navy.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final store = stores[index];
            return _buildStoreCard(store);
          },
          childCount: stores.length,
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final hasCoupon = store['hasCoupon'] as bool? ?? false;
    return GestureDetector(
      onTap: () => _launchStore(store['url']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppPalette.navy.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: hasCoupon ? AppPalette.orange.withValues(alpha: 0.3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: _buildStoreLogo(store),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(store['name'], store['nameEn']),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPalette.brandNavyDeep,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasCoupon ? tr('كود خصم متاح', 'Coupon available') : tr('زيارة المتجر', 'Visit Store'),
                      style: TextStyle(
                        color: AppPalette.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasCoupon)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppPalette.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreLogo(Map<String, dynamic> store) {
    final logoUrl = store['logoUrl'] as String?;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        proxiedImageUrl(logoUrl),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildTextLogo(store),
      );
    }
    return _buildTextLogo(store);
  }

  Widget _buildTextLogo(Map<String, dynamic> store) {
    final char = (store['name'] as String).characters.first;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppPalette.orange.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: AppPalette.orange,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore(String url) async {
    final affiliateUrl = AffiliateLinkService.prepareForOpen(url);
    final uri = Uri.parse(affiliateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}
