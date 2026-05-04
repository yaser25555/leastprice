import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';

class ShoppingCartNotifier extends StateNotifier<List<ComparisonSearchResult>> {
  ShoppingCartNotifier() : super([]);

  void addItem(ComparisonSearchResult item) {
    if (!state.any((element) => element.id == item.id)) {
      state = [...state, item];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + item.price);
  }
}

final shoppingCartProvider = StateNotifierProvider<ShoppingCartNotifier, List<ComparisonSearchResult>>((ref) {
  return ShoppingCartNotifier();
});
