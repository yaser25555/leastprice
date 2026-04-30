import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';

class SearchInfoPill extends StatelessWidget {
  const SearchInfoPill({super.key, 
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.softOrange,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.paleOrange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppPalette.orange),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.panelText,
              fontWeight: FontWeight.w800,
              fontSize: 12.8,
            ),
          ),
        ],
      ),
    );
  }
}
