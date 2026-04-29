import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_product_editor_dialog.dart';
import 'admin_exports.dart';

class AdminSimpleProductsPanel extends StatefulWidget {
  const AdminSimpleProductsPanel({super.key, required this.service});
  final FirestoreCatalogService service;

  @override
  State<AdminSimpleProductsPanel> createState() =>
      _AdminSimpleProductsPanelState();
}

class _AdminSimpleProductsPanelState extends State<AdminSimpleProductsPanel> {
  Future<void> _add() async {
    final product = await showDialog<ProductComparison>(
      context: context,
      builder: (_) => const AdminProductEditorDialog(),
    );
    if (product == null || !mounted) return;
    try {
      await widget.service.saveProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('تمت إضافة المنتج بنجاح.',
                  'Product added successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _edit(ProductComparison product) async {
    final updated = await showDialog<ProductComparison>(
      context: context,
      builder: (_) => AdminProductEditorDialog(initialProduct: product),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.service.saveProduct(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('تم تحديث المنتج بنجاح.',
                  'Product updated successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _delete(ProductComparison product) async {
    final docId = product.documentId;
    if (docId == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(tr(
                'هل تريد حذف "${product.expensiveName}"؟',
                'Do you want to delete "${product.expensiveName}"?')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('إلغاء', 'Cancel'))),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteProduct(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tr('تم حذف المنتج.', 'Product deleted.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _publishMockToFirestore() async {
    try {
      for (final p in ProductComparison.mockData) {
        await widget.service.saveProduct(p);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'تم نشر المنتجات التجريبية في Firestore.',
                  'Mock products were published to Firestore.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(
                'خطأ أثناء النشر: $e', 'Publishing error: $e'))));
      }
    }
  }

  Widget _buildProductCard(ProductComparison p, {bool isMock = false}) {
    return Card(
      color: isMock ? const Color(0xFFFFF8E1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1B2F5E),
          child: Text(
            p.categoryLabel.isNotEmpty ? p.categoryLabel[0] : '؟',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          '${p.expensiveName}  ?  ${p.alternativeName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          isMock
              ? '📦 تجريبي — ${p.categoryLabel} | ${p.expensivePrice} ر.س  →  ${p.alternativePrice} ر.س'
              : '${p.categoryLabel} | ${p.expensivePrice} ر.س  →  ${p.alternativePrice} ر.س',
          style: TextStyle(color: isMock ? Colors.orange[800] : null),
        ),
        trailing: isMock
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await widget.service.saveProduct(p);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(tr(
                                'تم نشر "${p.expensiveName}".',
                                '"${p.expensiveName}" was published.'))),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(tr('خطأ: $e', 'Error: $e'))));
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(tr('نشر', 'Publish')),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _edit(p)),
                  IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => _delete(p)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: StreamBuilder<List<ProductComparison>>(
        stream: widget.service.watchAllProducts(),
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final firestoreList = snap.data ?? [];
          final isMock = !isLoading && firestoreList.isEmpty;
          final displayList =
              isMock ? ProductComparison.mockData : firestoreList;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'بطاقات المقارنة',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2F5E)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMock)
                          OutlinedButton.icon(
                            onPressed: _publishMockToFirestore,
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: Text(tr('نشر الكل في Firestore',
                                'Publish all to Firestore')),
                          ),
                        if (isMock) const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(tr('إضافة منتج', 'Add product')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isMock)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Firestore فارغة — تعرض المنتجات التجريبية. اضغط "نشر" لحفظها.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      tr('خطأ: ${snap.error}', 'Error: ${snap.error}'),
                      style: const TextStyle(color: Colors.red)),
                ),
              if (isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildProductCard(displayList[i], isMock: isMock),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('إضافة منتج', 'Add product')),
      ),
    );
  }
}
