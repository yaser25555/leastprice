import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leastprice/core/utils/helpers.dart';

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.userId,
    required this.productTitle,
    required this.productUrl,
    required this.imageUrl,
    required this.storeId,
    required this.storeName,
    required this.targetPrice,
    this.currentPrice,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String productTitle;
  final String productUrl;
  final String imageUrl;
  final String storeId;
  final String storeName;
  final double targetPrice;
  final double? currentPrice;
  final bool active;
  final DateTime? createdAt;

  bool get hasTriggered =>
      currentPrice != null && currentPrice! <= targetPrice;

  PriceAlert copyWith({
    String? id,
    String? userId,
    String? productTitle,
    String? productUrl,
    String? imageUrl,
    String? storeId,
    String? storeName,
    double? targetPrice,
    double? currentPrice,
    bool? active,
    DateTime? createdAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productTitle: productTitle ?? this.productTitle,
      productUrl: productUrl ?? this.productUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      targetPrice: targetPrice ?? this.targetPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: stringValue(json['id']) ?? '',
      userId: stringValue(json['userId']) ?? '',
      productTitle: stringValue(json['productTitle']) ?? '',
      productUrl: stringValue(json['productUrl']) ?? '',
      imageUrl: stringValue(json['imageUrl']) ?? '',
      storeId: stringValue(json['storeId']) ?? '',
      storeName: stringValue(json['storeName']) ?? '',
      targetPrice: doubleValue(json['targetPrice']) ?? 0,
      currentPrice: doubleValue(json['currentPrice']),
      active: boolValue(json['active'], defaultValue: true),
      createdAt: dateTimeValue(json['createdAt']),
    );
  }

  factory PriceAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PriceAlert.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'productTitle': productTitle,
      'productUrl': productUrl,
      'imageUrl': imageUrl,
      'storeId': storeId,
      'storeName': storeName,
      'targetPrice': targetPrice,
      if (currentPrice != null) 'currentPrice': currentPrice,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }
}
