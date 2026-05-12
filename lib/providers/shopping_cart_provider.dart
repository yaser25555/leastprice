import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/cart_item.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ShoppingCartNotifier extends Notifier<List<CartItem>> {
  static const _key = 'shopping_cart';

  @override
  List<CartItem> build() {
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_key, raw);
    } catch (_) {}
  }

  void addItem(ComparisonSearchResult product) {
    final index = state.indexWhere(
      (item) => item.product.productUrl == product.productUrl,
    );
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(quantity: state[i].quantity + 1) else state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
    _saveToPrefs();
  }

  void removeItem(String productUrl) {
    state = state.where((item) => item.product.productUrl != productUrl).toList();
    _saveToPrefs();
  }

  void incrementQuantity(String productUrl) {
    state = [
      for (final item in state)
        if (item.product.productUrl == productUrl)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
    _saveToPrefs();
  }

  void decrementQuantity(String productUrl) {
    state = [
      for (final item in state)
        if (item.product.productUrl == productUrl && item.quantity > 1)
          item.copyWith(quantity: item.quantity - 1)
        else
          item,
    ];
    _saveToPrefs();
  }

  void clearCart() {
    state = [];
    _saveToPrefs();
  }

  double get totalPrice =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);

  Map<String, ({double total, int count})> get storeSummary {
    final map = <String, ({double total, int count})>{};
    for (final item in state) {
      final name = item.product.storeName;
      final existing = map[name] ?? (total: 0.0, count: 0);
      map[name] = (
        total: existing.total + item.totalPrice,
        count: existing.count + item.quantity,
      );
    }
    return map;
  }

  String get shareText {
    final buffer = StringBuffer();
    buffer.writeln('🛒 ${tr('سلة التوفير من LeastPrice', 'LeastPrice Savings Cart')}');
    buffer.writeln('==============================');
    for (final item in state) {
      buffer.writeln(
        '${item.product.title} x${item.quantity} — ${formatAmountValue(item.totalPrice)} ${item.product.currency}',
      );
    }
    buffer.writeln('==============================');
    buffer.writeln(
      '${tr('الإجمالي', 'Total')}: ${formatAmountValue(totalPrice)} SAR',
    );
    buffer.writeln();
    buffer.writeln('${tr('حمّل LeastPrice', 'Download LeastPrice')}: https://leastprice.app');
    return buffer.toString();
  }

  /// Returns the quantity for a given productUrl, or 0 if not in cart.
  int quantityOf(String productUrl) {
    final index = state.indexWhere((item) => item.product.productUrl == productUrl);
    return index >= 0 ? state[index].quantity : 0;
  }
}

final shoppingCartProvider =
    NotifierProvider<ShoppingCartNotifier, List<CartItem>>(() {
  return ShoppingCartNotifier();
});
