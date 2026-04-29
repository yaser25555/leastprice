import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ExclusiveDealCard extends StatelessWidget {
  const ExclusiveDealCard({super.key, 
    required this.deal,
    required this.now,
  });

  final ExclusiveDeal deal;
  final DateTime now;

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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF4ED), Color(0xFFFFE7E1)],
        ),
        border: Border.all(color: AppPalette.dealsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18D94B45),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                deal.imageUrl,
                width: 122,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 122,
                    color: AppPalette.softOrange,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: AppPalette.dealsRed,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0D0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFC4AE)),
                    ),
                    child: Text(
                      tr('عرض مؤقت', 'Limited deal'),
                      style: const TextStyle(
                        color: AppPalette.dealsRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    deal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1B2F5E),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        formatPrice(deal.afterPrice),
                        style: const TextStyle(
                          color: AppPalette.dealsRed,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatPrice(deal.beforePrice),
                        style: const TextStyle(
                          color: AppPalette.softNavy,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'وفرت ${deal.savingsPercent}% • $remainingLabel',
                      'Saved ${deal.savingsPercent}% ? $remainingLabel',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF8A3E2F),
                      fontWeight: FontWeight.w800,
                    ),
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
