import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminBannerManagerPanel extends StatefulWidget {
  const AdminBannerManagerPanel({
    super.key,
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<AdminBannerManagerPanel> createState() =>
      _AdminBannerManagerPanelState();
}

class _AdminBannerManagerPanelState extends State<AdminBannerManagerPanel> {
  Future<void> _openEditor({AdBannerItem? initialBanner}) async {
    final banner = await showDialog<AdBannerItem>(
      context: context,
      builder: (context) =>
          AdminBannerEditorDialog(initialBanner: initialBanner),
    );

    if (banner == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveAdBanner(banner);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialBanner == null
                ? tr('تمت إضافة البنر بنجاح.', 'Banner added successfully.')
                : tr('تم تحديث البنر بنجاح.', 'Banner updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ البنر حالياً: $error',
              'Unable to save the banner right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم تحديث lastUpdated للبنر بنجاح.',
              'Banner lastUpdated was refreshed successfully.',
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
              'تعذر نشر البنر حالياً: $error',
              'Unable to publish the banner right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
            content: Text(
              tr(
                'هل تريد حذف البنر "${banner.title}" نهائياً؟',
                'Do you want to permanently delete the banner "${banner.title}"?',
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
      await widget.catalogService.deleteAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف البنر.', 'Banner deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف البنر حالياً: $error',
              'Unable to delete the banner right now: $error',
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
                    'إدارة البنرات الإعلانية',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'أضف أو عدّل أو احذف البنرات في ad_banners مع نشر التحديث فوراً للمستخدمين.',
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
              label: Text(tr('إضافة بنر', 'Add banner')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdminDashboardSectionCard(
          child: StreamBuilder<List<AdBannerItem>>(
            stream: widget.catalogService.watchAdminAdBanners(),
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
                    'تعذر تحميل البنرات من Firestore: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7A9A)),
                  ),
                );
              }

              final banners = snapshot.data ?? const <AdBannerItem>[];
              if (banners.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد بنرات بعد. أضف أول بنر من الزر العلوي.',
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
                  children: banners.map((banner) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EFEA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminNetworkThumbnail(
                            imageUrl: banner.imageUrl,
                            label: banner.title,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF17332B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (banner.subtitle.trim().isNotEmpty)
                                  Text(
                                    banner.subtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF61756D),
                                      height: 1.4,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    AdminStatusChip(
                                      label: banner.active ? 'نشط' : 'مخفي',
                                      color: banner.active
                                          ? const Color(0xFFE8711A)
                                          : const Color(0xFF9A6B6B),
                                    ),
                                    AdminStatusChip(
                                      label: 'الترتيب ${banner.order}',
                                      color: const Color(0xFF375F54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 210,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _openEditor(initialBanner: banner),
                                  child: Text(tr('تعديل', 'Edit')),
                                ),
                                OutlinedButton(
                                  onPressed: () => _publishBanner(banner),
                                  child: Text(tr('نشر', 'Publish')),
                                ),
                                OutlinedButton(
                                  onPressed: () => _deleteBanner(banner),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC24E4E),
                                  ),
                                  child: Text(tr('حذف', 'Delete')),
                                ),
                              ],
                            ),
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
