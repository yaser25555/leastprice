import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_banner_editor_dialog.dart';
import 'admin_exports.dart';

class AdminSimpleBannersPanel extends StatefulWidget {
  const AdminSimpleBannersPanel({super.key, required this.service});
  final FirestoreCatalogService service;

  @override
  State<AdminSimpleBannersPanel> createState() =>
      _AdminSimpleBannersPanelState();
}

class _AdminSimpleBannersPanelState extends State<AdminSimpleBannersPanel> {
  Future<void> _add() async {
    final banner = await showDialog<AdBannerItem>(
      context: context,
      builder: (_) => const AdminBannerEditorDialog(),
    );
    if (banner == null || !mounted) return;
    try {
      await widget.service.saveAdBanner(banner);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('تمت إضافة البنر بنجاح.',
                  'Banner added successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _edit(AdBannerItem banner) async {
    final updated = await showDialog<AdBannerItem>(
      context: context,
      builder: (_) => AdminBannerEditorDialog(initialBanner: banner),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.service.saveAdBanner(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('تم تحديث البنر بنجاح.',
                  'Banner updated successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _delete(AdBannerItem banner) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
            content: Text(tr('هل تريد حذف "${banner.title}"؟',
                'Do you want to delete "${banner.title}"?')),
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
      await widget.service.deleteAdBanner(banner.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('تم حذف البنر.', 'Banner deleted.'))),
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
      for (final b in AdBannerItem.mockData) {
        await widget.service.saveAdBanner(b);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'تم نشر البنرات التجريبية في Firestore.',
                  'Mock banners were published to Firestore.'))),
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

  Widget _buildBannerCard(AdBannerItem b, {bool isMock = false}) {
    return Card(
      color: isMock ? const Color(0xFFFFF8E1) : null,
      child: ListTile(
        leading: b.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(b.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_rounded)),
              )
            : const Icon(Icons.image_rounded, size: 40),
        title:
            Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            [
              isMock
                  ? '📦 ${tr('تجريبي', 'Mock')} — ${b.storeName}'
                  : b.storeName,
            ].join(isMock ? ' — ' : '\n'),
            style: TextStyle(color: isMock ? Colors.orange[800] : null)),
        trailing: isMock
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await widget.service.saveAdBanner(b);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(tr(
                                'تم نشر "${b.title}" في Firestore.',
                                '"${b.title}" was published to Firestore.'))),
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
                      onPressed: () => _edit(b)),
                  IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => _delete(b)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      body: StreamBuilder<List<AdBannerItem>>(
        stream: widget.service.watchAdminAdBanners(),
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final firestoreList = snap.data ?? [];
          final isMock = !isLoading && firestoreList.isEmpty;
          final displayList = isMock ? AdBannerItem.mockData : firestoreList;

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
                      'البنرات الإعلانية',
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
                          label: Text(tr('إضافة بنر', 'Add banner')),
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
                          'Firestore فارغة — تعرض البنرات التجريبية. اضغط "نشر" لحفظها.',
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
                        _buildBannerCard(displayList[i], isMock: isMock),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('إضافة بنر', 'Add banner')),
      ),
    );
  }
}
