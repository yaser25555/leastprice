import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminExclusiveDealsTable extends StatefulWidget {
  const AdminExclusiveDealsTable({super.key, 
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<AdminExclusiveDealsTable> createState() =>
      _AdminExclusiveDealsTableState();
}

class _AdminExclusiveDealsTableState extends State<AdminExclusiveDealsTable> {
  Future<void> _openEditor({ExclusiveDeal? initialDeal}) async {
    final deal = await showDialog<ExclusiveDeal>(
      context: context,
      builder: (context) =>
          AdminExclusiveDealEditorDialog(initialDeal: initialDeal),
    );

    if (deal == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveExclusiveDeal(deal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialDeal == null
                ? tr('تمت إضافة العرض بنجاح.',
                    'Deal added successfully.')
                : tr('تم تحديث العرض بنجاح.',
                    'Deal updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ العرض حالياً: $error',
              'Unable to save the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishDeal(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'احفظ العرض أولاً قبل نشره.',
              'Save the deal first before publishing it.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await widget.catalogService.publishExclusiveDeal(deal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم نشر العرض وتحديث lastUpdated.',
              'The deal was published and lastUpdated was refreshed.',
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
              'تعذر نشر العرض حالياً: $error',
              'Unable to publish the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteDeal(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف العرض', 'Delete deal')),
            content: Text(
              tr(
                'هل تريد حذف "${deal.title}" نهائياً؟',
                'Do you want to permanently delete "${deal.title}"?',
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
      await widget.catalogService.deleteExclusiveDeal(deal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف العرض.', 'Deal deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف العرض حالياً: $error',
              'Unable to delete the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackHeight = math.max(
      520.0,
      MediaQuery.sizeOf(context).height - 220,
    );

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
                      tr('إدارة العروض الحصرية',
                          'Exclusive deals management'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      tr(
                        'أضف عروض exclusive_deals يدوياً مع السعر قبل وبعد وتاريخ الانتهاء، ثم استخدم زر النشر لتحديث lastUpdated فوراً.',
                        'Add exclusive_deals manually with before and after prices plus the expiry date, then use Publish to refresh lastUpdated immediately.',
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
                label: Text(tr('إضافة عرض', 'Add deal')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: fallbackHeight,
            child: AdminDashboardSectionCard(
              child: StreamBuilder<List<ExclusiveDeal>>(
                stream: widget.catalogService.watchAdminExclusiveDeals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(
                            'تعذر تحميل العروض من Firestore: ${snapshot.error}',
                            'Unable to load deals from Firestore: ${snapshot.error}',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final deals = snapshot.data ?? const <ExclusiveDeal>[];
                  if (deals.isEmpty) {
                    return Center(
                      child: Text(
                        tr(
                          'لا توجد عروض حصرية بعد. أضف أول عرض من الزر العلوي.',
                          'No exclusive deals yet. Add the first deal from the top button.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF6B7A9A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: WidgetStateProperty.all(
                          AppPalette.dealsSoftRed,
                        ),
                        columns: [
                          DataColumn(
                              label: Text(tr('العنوان', 'Title'))),
                          DataColumn(
                              label: Text(
                                  tr('السعر قبل', 'Before price'))),
                          DataColumn(
                              label:
                                  Text(tr('السعر بعد', 'After price'))),
                          DataColumn(
                              label: Text(tr('التوفير', 'Savings'))),
                          DataColumn(
                              label: Text(tr('الانتهاء', 'Expiry'))),
                          DataColumn(label: Text(tr('الحالة', 'Status'))),
                          DataColumn(label: Text(tr('الصورة', 'Image'))),
                          DataColumn(
                              label: Text(tr('الإجراءات', 'Actions'))),
                        ],
                        rows: deals.map((deal) {
                          final isExpired = deal.isExpiredAt(now);
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Text(
                                    deal.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                  Text(formatAmountValue(deal.beforePrice))),
                              DataCell(
                                  Text(formatAmountValue(deal.afterPrice))),
                              DataCell(
                                Text(
                                  '${formatAmountValue(deal.savingsAmount)} ? ${deal.savingsPercent}%',
                                ),
                              ),
                              DataCell(
                                  Text(formatDealExpiryLabel(deal.expiryDate))),
                              DataCell(
                                AdminStatusChip(
                                  label: isExpired
                                      ? tr('منتهي', 'Expired')
                                      : tr('ساري', 'Active'),
                                  color: isExpired
                                      ? AppPalette.dealsRed
                                      : AppPalette.orange,
                                ),
                              ),
                              DataCell(
                                AdminNetworkThumbnail(
                                  imageUrl: deal.imageUrl,
                                  label: deal.title,
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
                                        onPressed: () =>
                                            _openEditor(initialDeal: deal),
                                        child: Text(tr('تعديل', 'Edit')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishDeal(deal),
                                        child: Text(tr('نشر', 'Publish')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteDeal(deal),
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
  }
}
