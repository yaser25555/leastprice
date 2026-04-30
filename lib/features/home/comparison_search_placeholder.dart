import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';

class ComparisonSearchPlaceholder extends StatelessWidget {
  const ComparisonSearchPlaceholder({super.key, 
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppPalette.comparisonBorder),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppPalette.comparisonSoftEmerald,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: AppPalette.comparisonEmerald,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
