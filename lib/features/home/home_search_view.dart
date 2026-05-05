import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/features/home/home_search_provider.dart';
import 'package:leastprice/features/home/comparison_search_bar_section.dart';
import 'package:leastprice/features/home/comparison_search_placeholder.dart';
import 'package:leastprice/features/home/comparison_search_result_card.dart';
import 'package:leastprice/features/home/search_suggestions_carousel.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class HomeSearchView {
  static List<Widget> buildSlivers({
    required WidgetRef ref,
    required TextEditingController searchController,
    required FocusNode searchFocusNode,
    required Function(String) onOpenExternalUrl,
    required Function(String) onCopyCoupon,
    required bool isPaidPlanActive,
    required VoidCallback onDetectCityTap,
  }) {
    final state = ref.watch(homeSearchProvider);
    final notifier = ref.read(homeSearchProvider.notifier);

    final displayResults =
        isPaidPlanActive ? state.results : state.results.take(5).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: ComparisonSearchBarSection(
            searchController: searchController,
            focusNode: searchFocusNode,
            query: state.query,
            resultsCount: displayResults.length,
            dataSourceLabel: state.searchSourceLabel,
            searchHintText: tr(
              'ابحث عن أي منتج لمعرفة السعر الأقل',
              'Search any product to find the lowest price',
            ),
            isSearchingOnline: state.isSearchingOnline,
            availableCities: marketplaceSearchCities,
            selectedCityId: state.selectedCity.id,
            selectedCategory: state.selectedCategory,
            selectedStore: state.selectedStore,
            onCategorySelected: (category) {
              if (state.selectedCategory == category) {
                notifier.setCategory(null);
              } else {
                notifier.setCategory(category);
              }
            },
            onStoreSelected: (store) {
              notifier.setStore(store);
              if (state.query.trim().isNotEmpty && state.hasInternet) {
                notifier.performSearch(forceRefresh: true);
              }
            },
            onCitySelected: (cityId) {
              final city = marketplaceSearchCityById(cityId);
              if (city.id != state.selectedCity.id) {
                notifier.setCity(city);
                if (state.query.trim().isNotEmpty && state.hasInternet) {
                  notifier.performSearch(forceRefresh: true);
                }
              }
            },
            onClearSearch: () {
              searchController.clear();
              notifier.clearSearch();
            },
            onSubmitted: (value) {
              notifier.setQuery(value);
              notifier.performSearch(forceRefresh: true);
            },
            onDetectCityTap: onDetectCityTap,
          ),
        ),
      ),
      if (state.query.trim().isEmpty && !state.isSearchingOnline)
        const SliverToBoxAdapter(child: SearchSuggestionsCarousel())
      else if (state.isSearchingOnline && displayResults.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppPalette.comparisonEmerald,
              ),
            ),
          ),
        )
      else if (displayResults.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: ComparisonSearchPlaceholder(
              title: state.searchNotice?.trim().isNotEmpty == true
                  ? state.searchNotice!
                  : tr(
                      'أدخل اسم المنتج للبحث عن أقل سعر...',
                      'Enter product name to search for the lowest price...',
                    ),
              icon: Icons.manage_search_rounded,
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final result = displayResults[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == displayResults.length - 1 ? 0 : 18,
                  ),
                  child: ComparisonSearchResultCard(
                    result: result,
                    onTap: () => onOpenExternalUrl(result.productUrl),
                    onCopyCoupon: result.matchedCoupon == null
                        ? null
                        : () => onCopyCoupon(result.matchedCoupon!.code),
                  ),
                );
              },
              childCount: displayResults.length,
            ),
          ),
        ),
      if (state.searchNotice != null && displayResults.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.searchNotice!,
                  style: TextStyle(
                    color: AppPalette.softNavy,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (isPaidPlanActive && state.results.isNotEmpty && state.hasMoreResults)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Center(
              child: state.isLoadingMore
                  ? CircularProgressIndicator(
                      color: AppPalette.comparisonEmerald)
                  : TextButton.icon(
                      onPressed: () => notifier.performSearch(isLoadMore: true),
                      icon: Icon(Icons.expand_more_rounded,
                          color: AppPalette.comparisonEmerald),
                      label: Text(
                        tr('تحميل المزيد', 'Load More'),
                        style: TextStyle(
                          color: AppPalette.comparisonEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ),
        ),
    ];
  }
}
