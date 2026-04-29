import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class HomeSectionSwitcher extends StatelessWidget {
  const HomeSectionSwitcher({super.key, 
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final HomeCatalogSection selectedSection;
  final ValueChanged<HomeCatalogSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: HomeSectionSwitcherButton(
              label: tr('العروض', 'Offers'),
              icon: Icons.local_offer_rounded,
              isSelected: selectedSection == HomeCatalogSection.offers,
              activeColor: AppPalette.dealsRed,
              activeBackground: AppPalette.dealsSoftRed,
              onTap: () => onSectionSelected(HomeCatalogSection.offers),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HomeSectionSwitcherButton(
              label: tr('السعر الأقل', 'Lowest Price'),
              icon: Icons.compare_arrows_rounded,
              isSelected: selectedSection == HomeCatalogSection.comparisons,
              activeColor: AppPalette.comparisonEmerald,
              activeBackground: AppPalette.comparisonSoftEmerald,
              onTap: () => onSectionSelected(HomeCatalogSection.comparisons),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionSwitcherButton extends StatelessWidget {
  const HomeSectionSwitcherButton({super.key, 
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeBackground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppPalette.softNavy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppPalette.navy,
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
