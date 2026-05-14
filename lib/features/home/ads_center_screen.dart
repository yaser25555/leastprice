import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class AdsCenterScreen extends StatelessWidget {
  const AdsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildHeroSection(),
          _buildAdInfoSection(),
          _buildCallToAction(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppPalette.navy,
      centerTitle: true,
      title: Text(
        tr('مركز الإعلانات', 'Ads Center'),
        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.navy, AppPalette.navy.withValues(alpha: 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign_rounded, size: 80, color: AppPalette.orange),
            ),
            const SizedBox(height: 24),
            Text(
              tr('أعلن عن مشروعك هنا', 'Advertise Your Business Here'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('نصل بمتجرك أو مطعمك إلى آلاف المتسوقين يومياً في السعودية',
                  'Reach thousands of shoppers daily in Saudi Arabia'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdInfoSection() {
    final features = [
      {'icon': Icons.restaurant_rounded, 'title': 'المطاعم والكافيهات', 'titleEn': 'Restaurants & Cafes'},
      {'icon': Icons.local_mall_rounded, 'title': 'المتاجر المحلية', 'titleEn': 'Local Shops'},
      {'icon': Icons.trending_up_rounded, 'title': 'زيادة المبيعات', 'titleEn': 'Increase Sales'},
      {'icon': Icons.analytics_rounded, 'title': 'تقارير الأداء', 'titleEn': 'Performance Reports'},
    ];

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final f = features[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.navy.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppPalette.navy.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f['icon'] as IconData, color: AppPalette.orange, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    tr(f['title'] as String, f['titleEn'] as String),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.brandNavyDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: features.length,
        ),
      ),
    );
  }

  Widget _buildCallToAction() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppPalette.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                tr('جاهز للبدء؟', 'Ready to start?'),
                style: TextStyle(
                  color: AppPalette.brandNavyDeep,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('تواصل معنا الآن عبر الواتساب لحجز مساحتك الإعلانية',
                    'Contact us now via WhatsApp to book your ad space'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.navy.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(),
                icon: const Icon(Icons.chat_rounded),
                label: Text(tr('تواصل معنا', 'Contact Us')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const url = 'https://wa.me/966500000000'; // Placeholder number
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
