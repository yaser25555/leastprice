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
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.dealsBorder.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image Section
              Container(
                width: 120,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppPalette.softOrange,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.deepNavy.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  deal.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Icon(
                      Icons.local_offer_rounded,
                      color: AppPalette.dealsRed.withOpacity(0.5),
                      size: 32,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Details Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.dealsRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr('عرض حصري', 'Exclusive Deal'),
                        style: TextStyle(
                          color: AppPalette.dealsRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      deal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppPalette.deepNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    
                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(deal.afterPrice),
                          style: TextStyle(
                            color: AppPalette.dealsRed,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (deal.beforePrice > deal.afterPrice)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              formatPrice(deal.beforePrice),
                              style: TextStyle(
                                color: AppPalette.softNavy,
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Savings & Expiry
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppPalette.softNavy,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          remainingLabel,
                          style: TextStyle(
                            color: AppPalette.softNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (deal.savingsPercent > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tr('وفر ${deal.savingsPercent}%', 'Save ${deal.savingsPercent}%'),
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Action Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppPalette.softNavy.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

