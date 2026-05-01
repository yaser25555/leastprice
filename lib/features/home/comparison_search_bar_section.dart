import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/search_info_pill.dart';
import 'package:leastprice/features/search/barcode_scanner_screen.dart';
import 'home_exports.dart';

class ComparisonSearchBarSection extends StatelessWidget {
  const ComparisonSearchBarSection({super.key, 
    required this.searchController,
    required this.query,
    required this.resultsCount,
    required this.dataSourceLabel,
    required this.searchHintText,
    required this.isSearchingOnline,
    required this.availableCities,
    required this.selectedCityId,
    required this.onCitySelected,
    required this.onClearSearch,
    required this.onSubmitted,
    required this.onDetectCityTap,
  });

  final TextEditingController searchController;
  final String query;
  final int resultsCount;
  final String dataSourceLabel;
  final String searchHintText;
  final bool isSearchingOnline;
  final List<MarketplaceSearchCity> availableCities;
  final String selectedCityId;
  final ValueChanged<String> onCitySelected;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onDetectCityTap;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final appleStyle = isAppleInterface(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              appleStyle ? const Color(0xFFE5E7EE) : AppPalette.paleOrange,
          width: 1.5,
        ),
        boxShadow: AppPalette.premium3DBoxShadow,
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPalette.orange,
            ),
            decoration: InputDecoration(
              hintText: searchHintText,
              hintStyle: TextStyle(
                color: AppPalette.paleOrange,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppPalette.orange,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        onSubmitted(result);
                      }
                    },
                    icon: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppPalette.orange,
                    ),
                    tooltip: tr('بحث بالباركود', 'Search by barcode'),
                  ),
                  if (hasQuery)
                    IconButton(
                      onPressed: onClearSearch,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppPalette.orange,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: appleStyle ? AppPalette.cardBackground : AppPalette.deepNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: appleStyle
                    ? const Color(0xFFDCE1EA)
                    : AppPalette.paleOrange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppPalette.accentSkyDeep,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCityId,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(18),
                      dropdownColor: AppPalette.cardBackground,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppPalette.orange,
                        fontSize: 14.5,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppPalette.orange,
                      ),
                      items: availableCities
                          .map(
                            (city) => DropdownMenuItem<String>(
                              value: city.id,
                              child: Text(
                                city.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.orange,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        onCitySelected(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onDetectCityTap,
                  tooltip: tr('تحديد المدينة تلقائياً', 'Detect city automatically'),
                  icon: Icon(
                    Icons.my_location_rounded,
                    color: AppPalette.accentSkyDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SearchInfoPill(
                icon: Icons.inventory_2_outlined,
                label: tr(
                  '$resultsCount نتيجة',
                  '$resultsCount results',
                ),
              ),
              SearchInfoPill(
                icon: Icons.trending_down_rounded,
                label: tr('ترتيب من الأقل سعراً',
                    'Lowest price first'),
              ),
              SearchInfoPill(
                icon: isSearchingOnline
                    ? Icons.bolt_rounded
                    : Icons.cloud_done_rounded,
                label: isSearchingOnline
                    ? tr('جارٍ البحث...', 'Searching...')
                    : dataSourceLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
