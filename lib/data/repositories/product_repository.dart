import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/services/automation/smart_monitor_service.dart';
import 'package:leastprice/data/models/parsed_catalog_payload.dart';
import 'package:leastprice/data/models/catalog_refresh_result.dart';
import 'package:leastprice/data/models/product_load_result.dart';
import 'package:leastprice/core/utils/helpers.dart';

class ProductRepository {
  const ProductRepository({
    this.smartMonitorService = const SmartMonitorService(),
  });

  final SmartMonitorService smartMonitorService;

  Future<ProductLoadResult> loadProducts() async {
    String? notice;
    final remoteUrl = LeastPriceDataConfig.remoteJsonUrl.trim();
    final hasConfiguredRemoteUrl =
        remoteUrl.isNotEmpty && !remoteUrl.contains('your-domain.com');

    if (hasConfiguredRemoteUrl) {
      try {
        final remoteJson = await _fetchRemoteJson(remoteUrl);
        final payload = _parsePayload(remoteJson);
        if (payload.products.isNotEmpty) {
          return ProductLoadResult(
            products: _normalizeLoadedProducts(payload.products),
            source: ProductDataSource.remote,
            referralProfile: payload.referralProfile,
          );
        }
      } catch (_) {
        notice =
            'تعذر تحميل أحدث الأسعار من الرابط الخارجي، لذلك تم استخدام مصدر بديل.';
      }
    }

    try {
      final assetJson = await rootBundle.loadString(
        LeastPriceDataConfig.assetJsonPath,
      );
      final payload = _parsePayload(assetJson);
      if (payload.products.isNotEmpty) {
        return ProductLoadResult(
          products: _normalizeLoadedProducts(payload.products),
          source: ProductDataSource.asset,
          referralProfile: payload.referralProfile,
          notice: notice,
        );
      }
    } catch (_) {
      notice ??=
          'لم يتم العثور على ملف JSON خارجي، لذلك تم عرض البيانات التجريبية الحالية.';
    }

    return ProductLoadResult(
      products: _normalizeLoadedProducts(ProductComparison.mockData),
      source: ProductDataSource.mock,
      referralProfile: UserSavingsProfile.initial(),
      notice: notice ??
          'يمكنك لاحقاً ربط التطبيق بملف JSON أو رابط URL لتحديث الأسعار بدون إعادة نشر التطبيق.',
    );
  }

  Future<CatalogRefreshResult> refreshProductCatalog(
    List<ProductComparison> products,
  ) {
    return smartMonitorService.refreshProducts(products);
  }

  Future<String> _fetchRemoteJson(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unexpected status: ${response.statusCode}');
    }

    return response.body;
  }

  ParsedCatalogPayload _parsePayload(String rawJson) {
    final decoded = jsonDecode(rawJson);
    late final List<dynamic> rows;
    UserSavingsProfile? referralProfile;

    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final products = decoded['products'];
      if (products is! List) {
        throw const FormatException('Invalid products payload');
      }
      rows = products;

      final referral = decoded['referral'];
      if (referral is Map<String, dynamic>) {
        referralProfile = UserSavingsProfile.fromJson(referral);
      } else if (referral is Map) {
        referralProfile = UserSavingsProfile.fromJson(
          referral.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } else {
      throw const FormatException('Unsupported JSON structure');
    }

    return ParsedCatalogPayload(
      products: rows
          .map((row) =>
              ProductComparison.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      referralProfile: referralProfile,
    );
  }

  List<ProductComparison> _normalizeLoadedProducts(
    List<ProductComparison> products,
  ) {
    return products
        .map(
          (product) => product.copyWith(
            buyUrl: AffiliateLinkService.attachAffiliateTag(product.buyUrl),
          ),
        )
        .toList();
  }
}
