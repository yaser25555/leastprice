import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/core/utils/helpers.dart';

class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, 
    required this.comparison,
    required this.onTap,
  });

  final ProductComparison comparison;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reviewText = comparison.reviewCount > 0
        ? tr(
            '${comparison.rating.toStringAsFixed(1)} ⭐ - ${comparison.reviewCount} تقييم',
            '${comparison.rating.toStringAsFixed(1)} ? - ${comparison.reviewCount} reviews',
          )
        : tr('ابدأ أول تقييم لهذا الخيار',
            'Be the first to rate this option');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.softOrange,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.cardBorder),
        ),
        child: Row(
          children: [
            RatingStars(rating: comparison.rating),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewText,
                    style: const TextStyle(
                      color: Color(0xFF7A5A00),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'اضغط على النجوم لتقييم الجودة والقيمة مقارنة بالخيار الأعلى سعراً.',
                      'Tap the stars to rate quality and value compared to the higher-priced option.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF8B7331),
                      fontSize: 12.8,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFB79020),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, 
    required this.rating,
  });

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        IconData icon;

        if (rating >= starNumber) {
          icon = Icons.star_rounded;
        } else if (rating >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Icon(
          icon,
          color: const Color(0xFFF5B400),
          size: 20,
        );
      }),
    );
  }
}
