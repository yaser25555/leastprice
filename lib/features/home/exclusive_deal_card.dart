import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ExclusiveDealCard extends StatelessWidget {
  const ExclusiveDealCard({
    super.key,
    required this.deal,
    required this.now,
  });

  final ExclusiveDeal deal;
  final DateTime now;

  Future<void> _launchDeal() async {
    if (deal.dealUrl.isNotEmpty) {
      final uri = Uri.parse(deal.dealUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = deal.expiryDate.difference(now);
    final remainingLabel = remaining.inHours >= 24
        ? tr(
            'ينتهي خلال ${remaining.inDays + 1} يوم',
            'Ends in ${remaining.inDays + 1} day(s)',
          )
        : tr(
            'ينتهي خلال ${remaining.inHours.clamp(0, 23)} ساعة',
            'Ends in ${remaining.inHours.clamp(0, 23)} hour(s)',
          );

    return GestureDetector(
      onTap: _launchDeal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppPalette.dealsBorder.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Big Image Section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppPalette.softOrange,
                    child: Image.network(
                      deal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.local_offer_rounded,
                          color: AppPalette.dealsRed.withOpacity(0.5),
                          size: 64,
                        );
                      },
                    ),
                  ),
                  // Badge overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.dealsRed,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        tr('عرض حصري', 'Exclusive Deal'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section at the bottom
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          deal.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppPalette.deepNavy,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppPalette.dealsRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppPalette.dealsRed,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bottom Row: Timer & Action
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: AppPalette.softNavy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        remainingLabel,
                        style: TextStyle(
                          color: AppPalette.softNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (deal.beforePrice > 0 && deal.afterPrice > 0) ...[
                        Text(
                          formatPrice(deal.afterPrice),
                          style: TextStyle(
                            color: AppPalette.dealsRed,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ] else ...[
                        Text(
                          tr('تصفح المجلة الان', 'Browse Flyer Now'),
                          style: TextStyle(
                            color: AppPalette.dealsRed,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

