import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/models/price_alert.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/automation_health_status.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/data/repositories/product_repository.dart';
import 'package:leastprice/services/cache/cache_service.dart';

final firestoreCatalogProvider = Provider<FirestoreCatalogService>((ref) {
  return const FirestoreCatalogService();
});

final fallbackRepositoryProvider = Provider<ProductRepository>((ref) {
  return const ProductRepository();
});

final userProfileStreamProvider = StreamProvider.family
    .autoDispose<UserSavingsProfile?, String>((ref, userId) {
  final catalog = ref.watch(firestoreCatalogProvider);
  return catalog.watchUserProfile(userId);
});

final adBannersStreamProvider =
    StreamProvider.autoDispose<List<AdBannerItem>>((ref) async* {
  final catalog = ref.watch(firestoreCatalogProvider);
  final cache = CacheService.instance;

  final cached = await cache.getCachedBanners();
  if (cached != null && cached.isNotEmpty) {
    yield cached.map((json) => AdBannerItem.fromJson(json)).toList();
  }

  await for (final banners in catalog.watchAdBanners()) {
    final jsonList = banners.map((b) => b.toFirestoreMap()).toList();
    if (jsonList.isNotEmpty) {
      unawaited(cache.cacheBanners(jsonList));
    }
    yield banners;
  }
});

final systemHealthStreamProvider =
    StreamProvider.autoDispose<AutomationHealthStatus?>((ref) {
  final catalog = ref.watch(firestoreCatalogProvider);
  return catalog.watchSystemHealth();
});

final productsStreamProvider =
    StreamProvider.autoDispose<List<ProductComparison>>((ref) async* {
  final catalog = ref.watch(firestoreCatalogProvider);
  final cache = CacheService.instance;

  final cached = await cache.getCachedProducts();
  if (cached != null && cached.isNotEmpty) {
    yield cached
        .map((json) => ProductComparison.fromJson(json))
        .where((p) => p.buyUrl.trim().isNotEmpty)
        .toList();
  }

  await for (final products
      in catalog.watchProducts(categoryId: ProductCategoryCatalog.allId)) {
    final jsonList = products.map((p) => p.toFirestoreMap()).toList();
    if (jsonList.isNotEmpty) {
      unawaited(cache.cacheProducts(jsonList));
    }
    yield products;
  }
});
final favoritesStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  final catalog = ref.watch(firestoreCatalogProvider);
  return catalog.watchFavorites(user.uid);
});

final priceAlertsStreamProvider = StreamProvider.autoDispose<List<PriceAlert>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  final catalog = ref.watch(firestoreCatalogProvider);
  return catalog.watchPriceAlerts(user.uid);
});
