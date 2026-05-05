import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/services/api/serp_api_shopping_search_service.dart';

class HomeSearchState {
  final String query;
  final String? selectedCategory;
  final String selectedStore;
  final MarketplaceSearchCity selectedCity;
  final bool isSearchingOnline;
  final bool isDetectingCity;
  final String? searchNotice;
  final String searchSourceLabel;
  final List<ComparisonSearchResult> results;
  final bool hasInternet;
  final int currentOffset;
  final bool isLoadingMore;
  final bool hasMoreResults;

  const HomeSearchState({
    this.query = '',
    this.selectedCategory,
    this.selectedStore = 'الكل',
    required this.selectedCity,
    this.isSearchingOnline = false,
    this.isDetectingCity = false,
    this.searchNotice,
    this.searchSourceLabel = 'بحث السوق',
    this.results = const [],
    this.hasInternet = true,
    this.currentOffset = 0,
    this.isLoadingMore = false,
    this.hasMoreResults = true,
  });

  HomeSearchState copyWith({
    String? query,
    String? Function()? selectedCategory,
    String? selectedStore,
    MarketplaceSearchCity? selectedCity,
    bool? isSearchingOnline,
    bool? isDetectingCity,
    String? Function()? searchNotice,
    String? searchSourceLabel,
    List<ComparisonSearchResult>? results,
    bool? hasInternet,
    int? currentOffset,
    bool? isLoadingMore,
    bool? hasMoreResults,
  }) {
    return HomeSearchState(
      query: query ?? this.query,
      selectedCategory:
          selectedCategory != null ? selectedCategory() : this.selectedCategory,
      selectedStore: selectedStore ?? this.selectedStore,
      selectedCity: selectedCity ?? this.selectedCity,
      isSearchingOnline: isSearchingOnline ?? this.isSearchingOnline,
      isDetectingCity: isDetectingCity ?? this.isDetectingCity,
      searchNotice: searchNotice != null ? searchNotice() : this.searchNotice,
      searchSourceLabel: searchSourceLabel ?? this.searchSourceLabel,
      results: results ?? this.results,
      hasInternet: hasInternet ?? this.hasInternet,
      currentOffset: currentOffset ?? this.currentOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
    );
  }
}

class HomeSearchNotifier extends Notifier<HomeSearchState> {
  @override
  HomeSearchState build() {
    return HomeSearchState(selectedCity: marketplaceSearchCities.first);
  }

  final SerpApiShoppingSearchService _searchService =
      const SerpApiShoppingSearchService();

  void updateInternetStatus(bool hasInternet) {
    state = state.copyWith(hasInternet: hasInternet);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCity(MarketplaceSearchCity city) {
    state = state.copyWith(selectedCity: city);
  }

  void setStore(String store) {
    state = state.copyWith(selectedStore: store);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: () => category);
  }

  void clearSearch() {
    state = state.copyWith(
      results: [],
      searchNotice: () => null,
      searchSourceLabel: 'بحث السوق',
      isSearchingOnline: false,
      currentOffset: 0,
      hasMoreResults: true,
    );
  }

  Future<void> performSearch(
      {bool forceRefresh = false, bool isLoadMore = false}) async {
    if (state.query.trim().isEmpty || !state.hasInternet) {
      clearSearch();
      return;
    }

    if (isLoadMore) {
      if (state.isLoadingMore || !state.hasMoreResults) return;
      state = state.copyWith(isLoadingMore: true);
    } else {
      state = state.copyWith(
        isSearchingOnline: true,
        searchNotice: () => null,
        currentOffset: 0,
        hasMoreResults: true,
      );
    }

    try {
      String effectiveQuery = state.query.trim();
      // Category enhancement removed to keep search broad as requested

      String? targetStoreId;
      if (state.selectedStore != 'الكل' && state.selectedStore.isNotEmpty) {
        targetStoreId =
            inferStoreIdFromUrl('', fallbackName: state.selectedStore);
        final domain = domainForStoreId(state.selectedStore);
        if (domain != null) {
          effectiveQuery = '$effectiveQuery site:$domain';
        } else {
          effectiveQuery = '$effectiveQuery "${state.selectedStore}"';
        }
      }

      final nextOffset = isLoadMore ? state.currentOffset + 20 : 0;

      final result = await _searchService.search(
        query: effectiveQuery,
        firebaseReady: true, // Assuming true, handle appropriately
        forceRefresh: forceRefresh || isLoadMore,
        city: state.selectedCity,
        targetStoreId: targetStoreId,
        startOffset: nextOffset,
      );

      final newResults =
          isLoadMore ? [...state.results, ...result.results] : result.results;

      state = state.copyWith(
        results: newResults,
        currentOffset: nextOffset,
        hasMoreResults: result.results.isNotEmpty,
        query: result.effectiveQuery ?? state.query,
        searchNotice: () => result.results.isEmpty && !isLoadMore
            ? 'عذراً، لم نجد نتائج حالياً'
            : result.notice,
        searchSourceLabel: result.fromCache
            ? 'نتائج محفوظة • ${state.selectedCity.label}'
            : 'بحث حي • ${state.selectedCity.label}',
      );
    } catch (e) {
      if (!isLoadMore) {
        state = state.copyWith(
          results: [],
          searchNotice: () => 'عذراً، لم نجد نتائج حالياً',
          searchSourceLabel: 'بحث السوق',
        );
      }
    } finally {
      if (isLoadMore) {
        state = state.copyWith(isLoadingMore: false);
      } else {
        state = state.copyWith(isSearchingOnline: false);
      }
    }
  }
}

final homeSearchProvider =
    NotifierProvider<HomeSearchNotifier, HomeSearchState>(
        HomeSearchNotifier.new);
