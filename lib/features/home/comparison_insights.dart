import 'package:flutter/material.dart';

import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ComparisonInsights extends StatelessWidget {
  const ComparisonInsights({super.key, 
    required this.comparison,
    required this.onLocationTap,
  });

  final ProductComparison comparison;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comparison.fragranceNotes != null &&
              comparison.fragranceNotes!.trim().isNotEmpty)
            InsightRow(
              icon: Icons.spa_rounded,
              title: tr('نوتة العطر', 'Fragrance notes'),
              value: comparison.fragranceNotes!,
            ),
          if (comparison.activeIngredients != null &&
              comparison.activeIngredients!.trim().isNotEmpty)
            InsightRow(
              icon: Icons.science_rounded,
              title: tr('المادة الفعالة', 'Active ingredient'),
              value: comparison.activeIngredients!,
            ),
          if (comparison.localLocationLabel != null &&
              comparison.localLocationLabel!.trim().isNotEmpty)
            InsightRow(
              icon: Icons.place_rounded,
              title: tr('موقع المتجر', 'Store location'),
              value: comparison.localLocationLabel!,
              actionLabel: comparison.localLocationUrl == null
                  ? null
                  : tr('رابط الموقع', 'Open location'),
              onActionTap: onLocationTap,
            ),
        ],
      ),
    );
  }
}

class InsightRow extends StatelessWidget {
  const InsightRow({super.key, 
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE8711A), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF224238),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF5E756D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
