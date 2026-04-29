import 'package:flutter/material.dart';

import 'package:leastprice/data/models/product_category.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ProductCategoryCatalog {
  const ProductCategoryCatalog._();

  static const String allId = 'all';

  static const ProductCategory all = ProductCategory(
    id: allId,
    label: 'الكل',
    icon: Icons.grid_view_rounded,
    color: Color(0xFFE8711A),
  );

  static const List<ProductCategory> defaults = [
    all,
    ProductCategory(
      id: 'coffee',
      label: 'قهوة',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF8C5A2B),
    ),
    ProductCategory(
      id: 'roasters',
      label: 'محامص',
      icon: Icons.coffee_maker_rounded,
      color: Color(0xFFA54E2A),
    ),
    ProductCategory(
      id: 'restaurants',
      label: 'مطاعم',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE85D3F),
    ),
    ProductCategory(
      id: 'perfumes',
      label: 'عطور',
      icon: Icons.spa_rounded,
      color: Color(0xFFB05CC8),
    ),
    ProductCategory(
      id: 'cosmetics',
      label: 'تجميل',
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFE06F8A),
    ),
    ProductCategory(
      id: 'pharmacy',
      label: 'صيدلية',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF2F9E93),
    ),
    ProductCategory(
      id: 'detergents',
      label: 'منظفات',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF4D7CFE),
    ),
    ProductCategory(
      id: 'dairy',
      label: 'ألبان',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF3FA87B),
    ),
    ProductCategory(
      id: 'canned',
      label: 'معلبات',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF8A6C3F),
    ),
    ProductCategory(
      id: 'tea',
      label: 'شاي',
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF7B8E2F),
    ),
    ProductCategory(
      id: 'juice',
      label: 'عصير',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFFF8B3D),
    ),
  ];

  static ProductCategory lookup(String id, {String? fallbackLabel}) {
    for (final category in defaults) {
      if (category.id == id) {
        return category;
      }
    }

    return ProductCategory(
      id: id,
      label: fallbackLabel ?? id,
      icon: Icons.category_rounded,
      color: const Color(0xFFE8711A),
    );
  }

  static String inferId(String label) {
    final normalized = normalizeArabic(label);

    if (normalized.contains('محمص') ||
        normalized.contains('بن') ||
        normalized.contains('حبوب')) {
      return 'roasters';
    }
    if (normalized.contains('قهوه')) return 'coffee';
    if (normalized.contains('مطعم') ||
        normalized.contains('وجبه') ||
        normalized.contains('برجر')) {
      return 'restaurants';
    }
    if (normalized.contains('عطر') ||
        normalized.contains('برفيوم') ||
        normalized.contains('رائحه')) {
      return 'perfumes';
    }
    if (normalized.contains('تجميل') ||
        normalized.contains('سيروم') ||
        normalized.contains('كريم') ||
        normalized.contains('مكياج')) {
      return 'cosmetics';
    }
    if (normalized.contains('صيدلي') ||
        normalized.contains('صيدليه') ||
        normalized.contains('مرطب') ||
        normalized.contains('دواء')) {
      return 'pharmacy';
    }
    if (normalized.contains('منظف') || normalized.contains('تنظيف')) {
      return 'detergents';
    }
    if (normalized.contains('البان') ||
        normalized.contains('لبن') ||
        normalized.contains('حليب') ||
        normalized.contains('جبنه')) {
      return 'dairy';
    }
    if (normalized.contains('معلبات') ||
        normalized.contains('معلب') ||
        normalized.contains('معجون')) {
      return 'canned';
    }
    if (normalized.contains('شاي')) return 'tea';
    if (normalized.contains('عصير')) return 'juice';

    return normalized.replaceAll(' ', '_');
  }
}
