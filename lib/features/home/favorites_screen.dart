import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _service = const FirestoreCatalogService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('المفضلة', 'Favorites'))),
        body: Center(
          child: Text(tr('سجل دخول لحفظ المنتجات', 'Login to save favorites')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      appBar: AppBar(
        backgroundColor: AppPalette.cardBackground,
        surfaceTintColor: AppPalette.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(tr('المفضلة', 'Favorites')),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.watchFavorites(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    tr('لا توجد منتجات محفوظة', 'No saved products'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final fav = favorites[index];
              final title = fav['productTitle'] as String? ?? '';
              final price = (fav['price'] as num?)?.toDouble() ?? 0;
              final storeName = fav['storeName'] as String? ?? '';
              final imageUrl = fav['imageUrl'] as String? ?? '';
              final productUrl = fav['productUrl'] as String? ?? '';
              final currency = fav['currency'] as String? ?? 'SAR';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          proxiedImageUrl(imageUrl),
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64, height: 64,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image_outlined, color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(storeName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text('${formatAmountValue(price)} $currency',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                    color: AppPalette.comparisonEmerald)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _service.removeFavorite(productUrl),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
