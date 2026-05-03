import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/coupon.dart';

class ComparisonSearchResult {
  const ComparisonSearchResult({
    required this.title,
    required this.price,
    required this.storeName,
    required this.storeId,
    required this.storeLogoUrl,
    required this.imageUrl,
    required this.productUrl,
    required this.currency,
    required this.sourceType,
    required this.channelType,
    required this.isLiveDirect,
    this.matchedCoupon,
    this.tag,
  });

  final String title;
  final double price;
  final String storeName;
  final String storeId;
  final String storeLogoUrl;
  final String imageUrl;
  final String productUrl;
  final String currency;
  final ComparisonSearchSourceType sourceType;
  final ComparisonSearchChannelType channelType;
  final bool isLiveDirect;
  final Coupon? matchedCoupon;
  final String? tag;

  bool get isScraped => sourceType == ComparisonSearchSourceType.scraper;
  bool get isPreferredMarketplace {
    const preferred = {
      'noon', 'amazon', 'jarir', 'extra', 'nahdi', 'aldawaa', 
      'hungerstation', 'panda', 'othaim', 'carrefour', 'niceone', 
      'sephora', 'jahez', 'toyou', 'whites', 'lulu'
    };
    return preferred.contains(storeId.toLowerCase());
  }

  ComparisonSearchResult copyWith({
    String? title,
    double? price,
    String? storeName,
    String? storeId,
    String? storeLogoUrl,
    String? imageUrl,
    String? productUrl,
    String? currency,
    ComparisonSearchSourceType? sourceType,
    ComparisonSearchChannelType? channelType,
    bool? isLiveDirect,
    Coupon? matchedCoupon,
    bool clearMatchedCoupon = false,
    String? tag,
  }) {
    return ComparisonSearchResult(
      title: title ?? this.title,
      price: price ?? this.price,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      productUrl: productUrl ?? this.productUrl,
      currency: currency ?? this.currency,
      sourceType: sourceType ?? this.sourceType,
      channelType: channelType ?? this.channelType,
      isLiveDirect: isLiveDirect ?? this.isLiveDirect,
      matchedCoupon:
          clearMatchedCoupon ? null : (matchedCoupon ?? this.matchedCoupon),
      tag: tag ?? this.tag,
    );
  }

  factory ComparisonSearchResult.fromJson(Map<String, dynamic> json) {
    final title = stringValue(json['title'])?.trim() ?? '';
    final storeName = stringValue(
          json['storeName'] ?? json['source'] ?? json['seller'],
        )?.trim() ??
        '';
    final productUrl = stringValue(
          json['productUrl'] ?? json['product_link'] ?? json['link'],
        )?.trim() ??
        '';
    final thumbnails = json['thumbnails'];
    final imageUrl = normalizedImageUrl(
      stringValue(json['imageUrl'] ?? json['thumbnail']) ??
          (thumbnails is List && thumbnails.isNotEmpty
              ? stringValue(thumbnails.first) ?? ''
              : ''),
      fallbackLabel: title.isEmpty ? 'LeastPrice Result' : title,
    );
    final rawPriceText = stringValue(json['price']);
    final parsedFallbackPrice =
        rawPriceText == null ? null : extractMarketplacePrice(rawPriceText);
    final rawExtractedPrice = json['priceValue'] ?? json['extracted_price'];
    final extractedPrice =
        rawExtractedPrice == null ? null : doubleValue(rawExtractedPrice);
    final price = extractedPrice ?? parsedFallbackPrice ?? 0;
    final storeId = stringValue(json['storeId']) ??
        inferStoreIdFromUrl(productUrl, fallbackName: storeName) ??
        'unknown';
    final sourceType = comparisonSearchSourceTypeFromString(
      stringValue(json['sourceType']) ??
          (boolValue(
            json['isLiveDirect'] ?? json['isLiveScraped'],
            defaultValue: false,
          )
              ? 'scraper'
              : 'serpapi'),
    );
    final channelType = comparisonSearchChannelTypeFromString(
      stringValue(json['channelType']) ??
          inferComparisonChannelType(storeId, productUrl, storeName),
    );
    final currency = stringValue(json['currency']) ?? 'SAR';
    final rawMatchedCoupon = json['matchedCoupon'];

    return ComparisonSearchResult(
      title: title,
      price: price,
      storeId: storeId,
      storeLogoUrl: stringValue(json['storeLogoUrl']) ??
          resolveStoreLogoUrl(
            storeId: storeId,
            productUrl: productUrl,
            fallbackName: storeName,
          ),
      storeName:
          storeName.isEmpty ? tr('متجر إلكتروني', 'Online store') : storeName,
      imageUrl: imageUrl,
      productUrl: productUrl,
      currency: currency,
      sourceType: sourceType,
      channelType: channelType,
      isLiveDirect: boolValue(
        json['isLiveDirect'] ?? json['isLiveScraped'],
        defaultValue: sourceType == ComparisonSearchSourceType.scraper,
      ),
      matchedCoupon: rawMatchedCoupon is Map
          ? Coupon.fromJson(Map<String, dynamic>.from(rawMatchedCoupon))
          : null,
      tag: stringValue(json['tag']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priceValue': price,
      'price': '${formatAmountValue(price)} $currency',
      'storeName': storeName,
      'storeId': storeId,
      'storeLogoUrl': storeLogoUrl,
      'imageUrl': imageUrl,
      'productUrl': productUrl,
      'currency': currency,
      'sourceType': sourceType.name,
      'channelType': channelType.name,
      'isLiveDirect': isLiveDirect,
      if (matchedCoupon != null)
        'matchedCoupon': matchedCoupon!.toFirestoreMap(),
      if (tag != null) 'tag': tag,
    };
  }
}
