import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/search_info_pill.dart';
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
        boxShadow: [
          BoxShadow(
            color: appleStyle
                ? const Color(0x0D1B2F5E)
                : AppPalette.shadow,
            blurRadius: appleStyle ? 12 : 18,
            offset: Offset(0, appleStyle ? 6 : 12),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPalette.navy,
            ),
            decoration: InputDecoration(
              hintText: searchHintText,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: hasQuery
                  ? IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: appleStyle
                  ? AppPalette.softOrange
                  : AppPalette.softOrange.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: appleStyle
                    ? const Color(0xFFDCE1EA)
                    : AppPalette.paleOrange,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppPalette.navy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCityId,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(18),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: availableCities
                          .map(
                            (city) => DropdownMenuItem<String>(
                              value: city.id,
                              child: Text(
                                city.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.navy,
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
