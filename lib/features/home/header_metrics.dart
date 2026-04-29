import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';

class CompactMetricPill extends StatelessWidget {
  const CompactMetricPill({super.key, 
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x22E8711A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DFFD9BA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppPalette.paleOrange),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.paleOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactStatPill extends StatelessWidget {
  const CompactStatPill({super.key, 
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x18FFD9BA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55FFD9BA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppPalette.orange),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.paleOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
