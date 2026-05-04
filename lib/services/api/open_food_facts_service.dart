import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Fetches the product name in Arabic (if available) or English from a barcode.
  /// Returns the product name or null if not found.
  static Future<String?> getProductNameFromBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          
          // Try to get Arabic product name first
          String? name = product['product_name_ar'];
          
          // Fallback to English/generic name
          name ??= product['product_name_en'] ?? product['product_name'];
          
          // Add brand name if available for better search results
          final brand = product['brands']?.split(',').first;
          
          if (name != null && name.isNotEmpty) {
            if (brand != null && brand.isNotEmpty && !name.toLowerCase().contains(brand.toLowerCase())) {
              return '$brand $name'.trim();
            }
            return name.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('OpenFoodFacts Error: $e');
    }
    return null; // Return null if not found or on error
  }
}
