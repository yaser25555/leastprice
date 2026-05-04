import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';

class ShoppingCartNotifier extends Notifier<List<ComparisonSearchResult>> {
  @override
  List<ComparisonSearchResult> build() {
    return [];
  }

  void addItem(ComparisonSearchResult item) {
    if (!state.any((element) => element.productUrl == item.productUrl)) {
      state = [...state, item];
    }
  }

  void removeItem(String productUrl) {
    state = state.where((item) => item.productUrl != productUrl).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + item.price);
  }
}

final shoppingCartProvider = NotifierProvider<ShoppingCartNotifier, List<ComparisonSearchResult>>(() {
  return ShoppingCartNotifier();
});
