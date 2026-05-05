import 'package:flutter/material.dart';

import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/features/home/banner_carousel.dart';
import 'home_exports.dart';

class AdBannersSection extends StatelessWidget {
  const AdBannersSection({
    super.key,
    required this.banners,
    required this.onBannerTap,
  });

  final List<AdBannerItem> banners;
  final ValueChanged<AdBannerItem> onBannerTap;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: BannerCarousel(
        banners: banners,
        onTap: onBannerTap,
      ),
    );
  }
}
