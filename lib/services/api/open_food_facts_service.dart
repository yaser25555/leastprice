import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenFoodFactsService {
  static const List<String> _baseUrls = [
    'https://sa.openfoodfacts.org/api/v2/product',
    'https://world.openfoodfacts.org/api/v2/product',
  ];

  /// Fetches the product name in Arabic (if available) or English from a barcode.
  /// Returns the product name or null if not found.
  static Future<String?> getProductNameFromBarcode(String barcode) async {
    try {
      for (final baseUrl in _baseUrls) {
        final url = Uri.parse('$baseUrl/$barcode.json');
        final response = await http.get(
          url,
          headers: const {
            'Accept-Language': 'ar-SA,ar;q=0.9,en;q=0.8',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 1 && data['product'] != null) {
            final product = data['product'];
            String? name = product['product_name_ar'];
            name ??= product['product_name_en'] ?? product['product_name'];
            final brand = product['brands']?.split(',').first;

            if (name != null && name.isNotEmpty) {
              if (brand != null &&
                  brand.isNotEmpty &&
                  !name.toLowerCase().contains(brand.toLowerCase())) {
                return '$brand $name'.trim();
              }
              return name.trim();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OpenFoodFacts Error: $e');
    }
    return null; // Return null if not found or on error
  }
}
