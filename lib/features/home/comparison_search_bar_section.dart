import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/home/search_info_pill.dart';
import 'package:leastprice/features/search/barcode_scanner_screen.dart';
import 'package:leastprice/services/api/open_food_facts_service.dart';
import 'home_exports.dart';

class ComparisonSearchBarSection extends StatelessWidget {
  const ComparisonSearchBarSection({
    super.key,
    required this.searchController,
    required this.focusNode,
    required this.query,
    required this.resultsCount,
    required this.dataSourceLabel,
    required this.searchHintText,
    required this.isSearchingOnline,
    required this.availableCities,
    required this.selectedCityId,
    required this.selectedCategory,
    required this.selectedStore,
    required this.onCategorySelected,
    required this.onStoreSelected,
    required this.onCitySelected,
    required this.onClearSearch,
    required this.onSubmitted,
    required this.onDetectCityTap,
  });

  final TextEditingController searchController;
  final FocusNode focusNode;
  final String query;
  final int resultsCount;
  final String dataSourceLabel;
  final String searchHintText;
  final bool isSearchingOnline;
  final List<MarketplaceSearchCity> availableCities;
  final String selectedCityId;
  final String? selectedCategory;
  final String selectedStore;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onStoreSelected;
  final ValueChanged<String> onCitySelected;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onDetectCityTap;

  static const List<String> supportedStores = [
    'الكل',
    'بنده',
    'العثيم',
    'كارفور',
    'الدانوب',
    'التميمي',
    'لولو',
    'جرير',
    'اكسترا',
    'أمازون',
    'نون',
    'نمشي',
    'نايس ون',
    'قولدن سنت',
    'النهدي',
    'الدواء',
    'ايكيا',
    'ساكو',
    'ابيات',
    'هوم سنتر',
  ];

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final appleStyle = isAppleInterface(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.transparent),
        boxShadow: AppPalette.premium3DBoxShadow,
      ),
      child: Column(
        children: [
          RawAutocomplete<String>(
            focusNode: focusNode,
            textEditingController: searchController,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<String>.empty();
              }
              final query = textEditingValue.text.toLowerCase().trim();
              const popularSearchTerms = [
                'ايفون 15',
                'ايفون 15 برو ماكس',
                'ايفون 14',
                'سامسونج s24',
                'سامسونج s23 ultra',
                'شاشة ذكية 65 بوصة',
                'بلايستيشن 5',
                'حفاضات بامبرز',
                'حليب نيدو',
                'قهوة عربية',
                'كبسولات نسبريسو',
                'مكيف سبليت',
                'قلاية هوائية فيليبس',
                'لابتوب ابل ماك بوك',
                'عطر ديور سوفاج',
                'سماعات ابل ايربودز',
                'ساعة ابل',
                'زيت زيتون',
                'مياه نوفا'
              ];
              return popularSearchTerms.where((String option) {
                return option.contains(query);
              });
            },
            onSelected: (String selection) {
              onSubmitted(selection);
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 8.0, right: 16.0, left: 16.0),
                  child: Material(
                    color: AppPalette.cardBackground,
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 250,
                        maxWidth: MediaQuery.of(context).size.width -
                            64, // Accounts for padding
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => Divider(
                          color: AppPalette.panelText.withValues(alpha: 0.05),
                          height: 1,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search_rounded,
                                      size: 18, color: AppPalette.paleOrange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: AppPalette.panelText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.north_west_rounded,
                                      size: 16,
                                      color: AppPalette.paleOrange
                                          .withValues(alpha: 0.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  // Removed onFieldSubmitted() to prevent Autocomplete from overriding user's text
                  onSubmitted(value);
                },
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
                              builder: (context) =>
                                  const BarcodeScannerScreen(),
                            ),
                          );
                          if (result != null && result.isNotEmpty) {
                            if (!context.mounted) return;
                            // Show a loading dialog while fetching the product name
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(
                                    color: AppPalette.orange),
                              ),
                            );

                            final productName = await OpenFoodFactsService
                                .getProductNameFromBarcode(result);

                            // Close the loading dialog
                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            if (productName != null && productName.isNotEmpty) {
                              textEditingController.text = productName;
                              onSubmitted(productName);
                            } else {
                              // If OpenFoodFacts didn't find the product, fall back to searching by the raw barcode
                              textEditingController.text = result;
                              onSubmitted(result);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr(
                                        'لم نتمكن من التعرف على اسم المنتج، سنبحث برقم الباركود',
                                        'Could not identify product name, searching by barcode')),
                                    backgroundColor: AppPalette.dealsRed,
                                  ),
                                );
                              }
                            }
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
              );
            },
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  icon: Icons.electrical_services_rounded,
                  label: tr('الإلكترونيات', 'Electronics'),
                  isSelected:
                      selectedCategory == tr('الإلكترونيات', 'Electronics'),
                  onTap: () {
                    onCategorySelected(tr('الإلكترونيات', 'Electronics'));
                    focusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  icon: Icons.local_grocery_store_rounded,
                  label: tr('السوبر ماركت', 'Supermarket'),
                  isSelected:
                      selectedCategory == tr('السوبر ماركت', 'Supermarket'),
                  onTap: () {
                    onCategorySelected(tr('السوبر ماركت', 'Supermarket'));
                    focusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  icon: Icons.restaurant_rounded,
                  label: tr('المطاعم', 'Restaurants'),
                  isSelected: selectedCategory == tr('المطاعم', 'Restaurants'),
                  onTap: () {
                    onCategorySelected(tr('المطاعم', 'Restaurants'));
                    focusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  icon: Icons.local_cafe_rounded,
                  label: tr('المقاهي', 'Cafes'),
                  isSelected: selectedCategory == tr('المقاهي', 'Cafes'),
                  onTap: () {
                    onCategorySelected(tr('المقاهي', 'Cafes'));
                    focusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  icon: Icons.medical_services_rounded,
                  label: tr('العيادات الطبية', 'Medical Clinics'),
                  isSelected: selectedCategory ==
                      tr('العيادات الطبية', 'Medical Clinics'),
                  onTap: () {
                    onCategorySelected(
                        tr('العيادات الطبية', 'Medical Clinics'));
                    focusNode.requestFocus();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: appleStyle
                      ? AppPalette.cardBackground
                      : AppPalette.deepNavy,
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
                            if (value != null) onCitySelected(value);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDetectCityTap,
                      tooltip: tr('تحديد المدينة تلقائياً',
                          'Detect city automatically'),
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: AppPalette.accentSkyDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: appleStyle
                      ? AppPalette.cardBackground
                      : AppPalette.deepNavy,
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
                      Icons.storefront_outlined,
                      color: AppPalette.accentSkyDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStore,
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
                          items: supportedStores
                              .map(
                                (store) => DropdownMenuItem<String>(
                                  value: store,
                                  child: Text(
                                    store,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.orange,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) onStoreSelected(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                label: tr('ترتيب من الأقل سعراً', 'Lowest price first'),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon,
          color: isSelected ? AppPalette.pureWhite : AppPalette.orange,
          size: 16),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppPalette.pureWhite : AppPalette.panelText,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      backgroundColor:
          isSelected ? AppPalette.orange : AppPalette.cardBackground,
      side: BorderSide(
          color: isSelected ? AppPalette.orange : AppPalette.cardBorder,
          width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: onTap,
    );
  }
}
