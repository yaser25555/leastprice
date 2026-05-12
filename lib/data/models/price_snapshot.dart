import 'package:cloud_firestore/cloud_firestore.dart';

class PriceSnapshot {
  final String id;
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final String currency;
  final DateTime recordedAt;

  const PriceSnapshot({
    required this.id,
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.recordedAt,
  });

  factory PriceSnapshot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['recordedAt'];
    return PriceSnapshot(
      id: doc.id,
      productId: (data['productId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      price: ((data['price'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'SAR',
      recordedAt: (ts is Timestamp ? ts.toDate() : DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
        'productId': productId,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'currency': currency,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
}
