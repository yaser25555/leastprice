import 'dart:convert';

import 'package:hive/hive.dart';

class CacheService {
  CacheService._();

  static final CacheService _instance = CacheService._();
  static CacheService get instance => _instance;

  static const _productsKey = 'cached_products';
  static const _couponsKey = 'cached_coupons';
  static const _dealsKey = 'cached_deals';
  static const _bannersKey = 'cached_banners';

  static const _ttlProducts = Duration(hours: 2);
  static const _ttlCoupons = Duration(hours: 6);
  static const _ttlDeals = Duration(hours: 2);
  static const _ttlBanners = Duration(hours: 6);

  Box? _box;

  Future<Box> get _store async {
    if (_box != null) return _box!;
    _box = await Hive.openBox('app_cache');
    return _box!;
  }

  // ── Products ──

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final box = await _store;
    await box.put(_productsKey, jsonEncode({
      'data': products,
      'cachedAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<List<Map<String, dynamic>>?> getCachedProducts() async {
    final box = await _store;
    final raw = box.get(_productsKey) as String?;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttlProducts) return null;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Coupons ──

  Future<void> cacheCoupons(List<Map<String, dynamic>> coupons) async {
    final box = await _store;
    await box.put(_couponsKey, jsonEncode({
      'data': coupons,
      'cachedAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<List<Map<String, dynamic>>?> getCachedCoupons() async {
    final box = await _store;
    final raw = box.get(_couponsKey) as String?;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttlCoupons) return null;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Exclusive Deals ──

  Future<void> cacheDeals(List<Map<String, dynamic>> deals) async {
    final box = await _store;
    await box.put(_dealsKey, jsonEncode({
      'data': deals,
      'cachedAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<List<Map<String, dynamic>>?> getCachedDeals() async {
    final box = await _store;
    final raw = box.get(_dealsKey) as String?;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttlDeals) return null;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Ad Banners ──

  Future<void> cacheBanners(List<Map<String, dynamic>> banners) async {
    final box = await _store;
    await box.put(_bannersKey, jsonEncode({
      'data': banners,
      'cachedAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<List<Map<String, dynamic>>?> getCachedBanners() async {
    final box = await _store;
    final raw = box.get(_bannersKey) as String?;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttlBanners) return null;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Clear ──

  Future<void> clearAll() async {
    final box = await _store;
    await box.clear();
  }
}
