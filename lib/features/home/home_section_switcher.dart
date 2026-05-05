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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: appleStyle ? const Color(0xFFDCE0E8) : AppPalette.cardBorder,
        ),
        boxShadow: appleStyle
            ? const []
            : [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              label: tr('الباقات', 'Plans'),
              icon: Icons.workspace_premium_rounded,
              isSelected: selectedSection == HomeCatalogSection.plans,
              activeColor: AppPalette.orangeCrimson,
              activeBackground: AppPalette.orangeWarm,
              activeGradient: AppPalette.gradientWarmCta,
              activeIconColor: AppPalette.pureWhite,
              onTap: () => onSectionSelected(HomeCatalogSection.plans),
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
    this.activeGradient,
    this.activeIconColor,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onTap;
  final Gradient? activeGradient;
  final Color? activeIconColor;

  @override
  Widget build(BuildContext context) {
    final appleStyle = isAppleInterface(context);
    final useGradient = isSelected && activeGradient != null && !appleStyle;
    final tileBackground = isSelected
        ? (appleStyle ? AppPalette.softOrange : activeBackground)
        : (appleStyle ? const Color(0xFFF3F4F8) : AppPalette.softNavy);
    final iconColor = isSelected
        ? (useGradient
            ? (activeIconColor ?? AppPalette.pureWhite)
            : activeColor)
        : (appleStyle ? AppPalette.navy : AppPalette.panelText);
    final borderColor = isSelected
        ? (appleStyle
            ? const Color(0xFFD9DEE8)
            : activeColor.withValues(alpha: 0.45))
        : (appleStyle
            ? const Color(0xFFE2E5EC)
            : AppPalette.cardBorder.withValues(alpha: 0.35));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: useGradient ? null : tileBackground,
                gradient: useGradient ? activeGradient : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : const [],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? activeColor : AppPalette.navy,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
