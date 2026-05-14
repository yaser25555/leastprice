import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/features/home/banner_carousel.dart';
import 'package:leastprice/features/home/exclusive_deal_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AdsCenterSection extends StatelessWidget {
  const AdsCenterSection({
    super.key,
    required this.adsStream,
    required this.dealsStream,
    required this.onAdTap,
  });

  final Stream<List<AdBannerItem>> adsStream;
  final Stream<List<ExclusiveDeal>> dealsStream;
  final ValueChanged<AdBannerItem> onAdTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLiveAds(),
        const SizedBox(height: 20),
        _buildLiveDeals(),
        const SizedBox(height: 30),
        _buildHeroSection(),
        _buildAdInfoSection(),
        _buildCallToAction(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLiveAds() {
    return StreamBuilder<List<AdBannerItem>>(
      stream: adsStream,
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        if (ads.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Text(
                tr('عروض مميزة', 'Featured Ads'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppPalette.navy),
              ),
            ),
            BannerCarousel(
              banners: ads,
              onTap: onAdTap,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveDeals() {
    final now = DateTime.now();
    return StreamBuilder<List<ExclusiveDeal>>(
      stream: dealsStream,
      builder: (context, snapshot) {
        final deals = snapshot.data ?? [];
        if (deals.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Text(
                tr('أقوى العروض الحصرية', 'Exclusive Deals'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppPalette.navy),
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: deals.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: SizedBox(
                      width: 220,
                      child: ExclusiveDealCard(
                        deal: deals[index],
                        now: now,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.navy, AppPalette.navy.withValues(alpha: 0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_rounded, size: 60, color: AppPalette.orange),
          ),
          const SizedBox(height: 24),
          Text(
            tr('أعلن عن مشروعك هنا', 'Advertise Here'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('نصل بمشروعك إلى آلاف المتسوقين',
                'Reach thousands of shoppers'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdInfoSection() {
    final features = [
      {'icon': Icons.restaurant_rounded, 'title': 'مطاعم وكافيهات', 'titleEn': 'Restaurants'},
      {'icon': Icons.local_mall_rounded, 'title': 'متاجر محلية', 'titleEn': 'Local Shops'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: features.map((f) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
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
            ),
            child: Column(
              children: [
                Icon(f['icon'] as IconData, color: AppPalette.orange, size: 28),
                const SizedBox(height: 10),
                Text(
                  tr(f['title'] as String, f['titleEn'] as String),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppPalette.brandNavyDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCallToAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () => _launchWhatsApp(),
          icon: const Icon(Icons.chat_rounded),
          label: Text(tr('تواصل معنا للإعلان', 'Contact for Ads')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const url = 'https://wa.me/966558570889'; 
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
