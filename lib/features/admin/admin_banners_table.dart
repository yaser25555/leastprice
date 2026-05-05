import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminBannersTable extends StatefulWidget {
  const AdminBannersTable({
    super.key,
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<AdminBannersTable> createState() => _AdminBannersTableState();
}

class _AdminBannersTableState extends State<AdminBannersTable> {
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
                ? 'تمت إضافة البنر بنجاح.'
                : 'تم تحديث البنر بنجاح.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تعذر حفظ البنر حالياً: $error',
                'Unable to save the banner right now: $error'))),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تم تحديث lastUpdated للبنر بنجاح.',
                'Banner lastUpdated was refreshed successfully.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('تعذر نشر البنر حالياً: $error',
                'Unable to publish the banner right now: $error'))),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
            content: Text(tr('هل تريد حذف البنر "${banner.title}" نهائياً؟',
                'Do you want to permanently delete the banner "${banner.title}"?')),
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
            content: Text(tr('تعذر حذف البنر حالياً: $error',
                'Unable to delete the banner right now: $error'))),
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
                            tr('إدارة البنرات الإعلانية', 'Banner management'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2F5E),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            tr(
                              'أضف أو عدّل أو احذف البنرات في مجموعة ad_banners، ثم استخدم زر النشر لتحديث lastUpdated.',
                              'Add, edit, or delete banners in the ad_banners collection, then use Publish to refresh lastUpdated.',
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
                      label: Text(tr('إضافة بنر', 'Add banner')),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: sectionHeight,
                  child: AdminDashboardSectionCard(
                    child: StreamBuilder<List<AdBannerItem>>(
                      stream: widget.catalogService.watchAdminAdBanners(),
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
                                  'تعذر تحميل البنرات من Firestore: ${snapshot.error}',
                                  'Unable to load banners from Firestore: ${snapshot.error}',
                                ),
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Color(0xFF6B7A9A)),
                              ),
                            ),
                          );
                        }

                        final banners = snapshot.data ?? const <AdBannerItem>[];
                        if (banners.isEmpty) {
                          return Center(
                            child: Text(
                              tr(
                                'لا توجد بنرات بعد. أضف أول بنر من الزر العلوي.',
                                'No banners yet. Add the first banner from the top button.',
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
                                DataColumn(label: Text(tr('المتجر', 'Store'))),
                                DataColumn(label: Text(tr('العنوان', 'Title'))),
                                DataColumn(label: Text(tr('الترتيب', 'Order'))),
                                DataColumn(label: Text(tr('الحالة', 'Status'))),
                                DataColumn(label: Text(tr('الصورة', 'Image'))),
                                DataColumn(
                                    label: Text(tr('الإجراءات', 'Actions'))),
                              ],
                              rows: banners.map((banner) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(banner.storeName)),
                                    DataCell(
                                      SizedBox(
                                        width: 240,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              banner.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if (banner.subtitle
                                                .trim()
                                                .isNotEmpty)
                                              Text(
                                                banner.subtitle,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF667C74),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(banner.order.toString())),
                                    DataCell(
                                      AdminStatusChip(
                                        label: banner.active
                                            ? tr('نشط', 'Active')
                                            : tr('مخفي', 'Hidden'),
                                        color: banner.active
                                            ? const Color(0xFFE8711A)
                                            : const Color(0xFF9A6B6B),
                                      ),
                                    ),
                                    DataCell(
                                      AdminNetworkThumbnail(
                                        imageUrl: banner.imageUrl,
                                        label: banner.title,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => _openEditor(
                                                  initialBanner: banner),
                                              child: Text(tr('تعديل', 'Edit')),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _publishBanner(banner),
                                              child: Text(tr('نشر', 'Publish')),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _deleteBanner(banner),
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
      debugPrint('Admin banners table build failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return AdminBuildFailurePanel(message: error.toString());
    }
  }
}
