import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminProductsTable extends StatefulWidget {
  const AdminProductsTable({
    super.key,
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<AdminProductsTable> createState() => _AdminProductsTableState();
}

class _AdminProductsTableState extends State<AdminProductsTable> {
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
                ? 'تمت إضافة المنتج بنجاح.'
                : 'تم تحديث المنتج بنجاح.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تعذر حفظ المنتج حالياً: $error',
                'Unable to save the product right now: $error'))),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('احفظ المنتج أولاً قبل نشره.',
                'Save the product first before publishing it.'))),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تم تحديث lastUpdated للمنتج بنجاح.',
                'Product lastUpdated was refreshed successfully.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تعذر نشر المنتج حالياً: $error',
                'Unable to publish the product right now: $error'))),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('هذا المنتج غير مرتبط بوثيقة Firestore.',
                'This product is not linked to a Firestore document.'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(
              'هل تريد حذف "${product.expensiveName}" و"${product.alternativeName}" نهائياً؟',
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
            content: Text(tr('تعذر حذف المنتج حالياً: $error',
                'Unable to delete the product right now: $error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fallbackHeight = math.max(
            520.0,
            MediaQuery.sizeOf(context).height - 220,
          );
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackHeight;
          final sectionHeight = math.max(520.0, availableHeight - 64);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('إدارة المنتجات', 'Product management'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2F5E),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            tr(
                              'هذه هي بطاقات المقارنة المستمرة من مجموعة products. يتم وسمها كبيانات آلية مع تحديث lastUpdated عند النشر.',
                              'These are the ongoing comparison cards from the products collection. They are tagged as automated data and refresh lastUpdated when published.',
                            ),
                            style: const TextStyle(
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
                SizedBox(
                  height: sectionHeight,
                  child: AdminDashboardSectionCard(
                    child: StreamBuilder<List<ProductComparison>>(
                      stream: widget.catalogService.watchAllProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                tr(
                                  'تعذر تحميل المنتجات من Firestore: ${snapshot.error}',
                                  'Unable to load products from Firestore: ${snapshot.error}',
                                ),
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Color(0xFF6B7A9A)),
                              ),
                            ),
                          );
                        }

                        final products =
                            snapshot.data ?? const <ProductComparison>[];
                        if (products.isEmpty) {
                          return Center(
                            child: Text(
                              tr(
                                'لا توجد منتجات بعد. أضف أول منتج من الزر العلوي.',
                                'No products yet. Add the first product from the top button.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF6B7A9A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 18,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF2FBF7),
                              ),
                              columns: [
                                DataColumn(
                                    label: Text(tr('القسم', 'Category'))),
                                DataColumn(label: Text(tr('النوع', 'Type'))),
                                DataColumn(
                                  label: Text(tr(
                                      'المنتج المرجعي', 'Reference product')),
                                ),
                                DataColumn(label: Text(tr('سعره', 'Price'))),
                                DataColumn(
                                  label: Text(
                                      tr('الخيار المقارن', 'Compared option')),
                                ),
                                DataColumn(label: Text(tr('سعره', 'Price'))),
                                DataColumn(label: Text(tr('الصور', 'Images'))),
                                DataColumn(
                                    label: Text(tr('واتساب', 'WhatsApp'))),
                                DataColumn(
                                    label: Text(tr('الإجراءات', 'Actions'))),
                              ],
                              rows: products.map((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        localizedCategoryLabelForId(
                                          product.categoryId,
                                          fallbackLabel: product.categoryLabel,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      AdminStatusChip(
                                        label: product.isAutomated
                                            ? tr('آلي', 'Automated')
                                            : tr('يدوي', 'Manual'),
                                        color: product.isAutomated
                                            ? AppPalette.comparisonEmerald
                                            : AppPalette.orange,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: Text(
                                          product.expensiveName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(formatAmountValue(
                                        product.expensivePrice))),
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: Text(
                                          product.alternativeName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(formatAmountValue(
                                          product.alternativePrice)),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AdminNetworkThumbnail(
                                            imageUrl: product.expensiveImageUrl,
                                            label: product.expensiveName,
                                          ),
                                          const SizedBox(width: 8),
                                          AdminNetworkThumbnail(
                                            imageUrl:
                                                product.alternativeImageUrl,
                                            label: product.alternativeName,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          product.buyUrl.trim().isEmpty
                                              ? tr('بدون واتساب', 'No WhatsApp')
                                              : product.buyUrl,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 270,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => _openEditor(
                                                  initialProduct: product),
                                              child: Text(tr('تعديل', 'Edit')),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _publishProduct(product),
                                              child: Text(tr('نشر', 'Publish')),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _deleteProduct(product),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFFC24E4E),
                                              ),
                                              child: Text(tr('حذف', 'Delete')),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Admin products table build failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return AdminBuildFailurePanel(message: error.toString());
    }
  }
}
