import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class HomeSectionSwitcher extends StatelessWidget {
  const HomeSectionSwitcher({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final HomeCatalogSection selectedSection;
  final ValueChanged<HomeCatalogSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final appleStyle = isAppleInterface(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: appleStyle
              ? const Color(0xFFDCE0E8)
              : AppPalette.cardBorder,
        ),
        boxShadow: appleStyle
            ? const []
            : const [
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
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
          Expanded(
            child: HomeSectionSwitcherButton(
              label: tr('كوبونات', 'Coupons'),
              icon: Icons.confirmation_number_rounded,
              isSelected: selectedSection == HomeCatalogSection.coupons,
              activeColor: AppPalette.orange,
              activeBackground: AppPalette.deepNavy,
              onTap: () => onSectionSelected(HomeCatalogSection.coupons),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: HomeSectionSwitcherButton(
              label: tr('من نحن', 'About Us'),
              icon: Icons.info_rounded,
              isSelected: selectedSection == HomeCatalogSection.about,
              activeColor: AppPalette.navy,
              activeBackground: AppPalette.softOrange,
              onTap: () => onSectionSelected(HomeCatalogSection.about),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionSwitcherButton extends StatelessWidget {
  const HomeSectionSwitcherButton({
    super.key,
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
    final appleStyle = isAppleInterface(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? (appleStyle ? AppPalette.softOrange : activeBackground)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? (appleStyle
                    ? const Color(0xFFD9DEE8)
                    : activeColor.withValues(alpha: 0.35))
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppPalette.softNavy,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? activeColor : AppPalette.navy,
                fontWeight: FontWeight.w900,
                fontSize: 12.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
