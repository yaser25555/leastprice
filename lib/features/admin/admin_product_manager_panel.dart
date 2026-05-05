import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminProductManagerPanel extends StatefulWidget {
  const AdminProductManagerPanel({
    super.key,
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<AdminProductManagerPanel> createState() =>
      _AdminProductManagerPanelState();
}

class _AdminProductManagerPanelState extends State<AdminProductManagerPanel> {
  Future<void> _openEditor({ProductComparison? initialProduct}) async {
    final product = await showDialog<ProductComparison>(
      context: context,
      builder: (context) =>
          AdminProductEditorDialog(initialProduct: initialProduct),
    );

    if (product == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialProduct == null
                ? tr('تمت إضافة المنتج بنجاح.', 'Product added successfully.')
                : tr('تم تحديث المنتج بنجاح.', 'Product updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ المنتج حالياً: $error',
              'Unable to save the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'احفظ المنتج أولاً قبل نشره.',
              'Save the product first before publishing it.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم تحديث lastUpdated للمنتج بنجاح.',
              'Product lastUpdated was refreshed successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر نشر المنتج حالياً: $error',
              'Unable to publish the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'هذا المنتج غير مرتبط بوثيقة Firestore.',
              'This product is not linked to a Firestore document.',
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(
              tr(
                'هل تريد حذف "${product.expensiveName}" و"${product.alternativeName}" نهائياً؟',
                'Do you want to permanently delete "${product.expensiveName}" and "${product.alternativeName}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف المنتج.', 'Product deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف المنتج حالياً: $error',
              'Unable to delete the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة المنتجات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'عدّل الأسماء والأسعار والصور ثم انشر التحديث ليظهر فوراً داخل التطبيق.',
                    style: TextStyle(
                      color: Color(0xFF667C74),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('إضافة منتج', 'Add product')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdminDashboardSectionCard(
          child: StreamBuilder<List<ProductComparison>>(
            stream: widget.catalogService.watchAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل المنتجات من Firestore: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7A9A)),
                  ),
                );
              }

              final products = snapshot.data ?? const <ProductComparison>[];
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد منتجات بعد. أضف أول منتج من الزر العلوي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7A9A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: products.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EFEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminNetworkThumbnail(
                                imageUrl: product.expensiveImageUrl,
                                label: product.expensiveName,
                              ),
                              const SizedBox(width: 10),
                              AdminNetworkThumbnail(
                                imageUrl: product.alternativeImageUrl,
                                label: product.alternativeName,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.categoryLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF6A7C74),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.expensiveName}  ?  ${formatAmountValue(product.expensivePrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF17332B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.alternativeName}  ?  ${formatAmountValue(product.alternativePrice)}',
                                      style: const TextStyle(
                                        color: Color(0xFF436459),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (product.buyUrl.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        product.buyUrl,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF6D8079),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _openEditor(initialProduct: product),
                                child: Text(tr('تعديل', 'Edit')),
                              ),
                              OutlinedButton(
                                onPressed: () => _publishProduct(product),
                                child: Text(tr('نشر', 'Publish')),
                              ),
                              OutlinedButton(
                                onPressed: () => _deleteProduct(product),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC24E4E),
                                ),
                                child: Text(tr('حذف', 'Delete')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
