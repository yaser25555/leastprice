import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_exclusive_deal_editor_dialog.dart';
import 'package:leastprice/services/api/dcm_network_service.dart';

class AdminSimpleExclusiveDealsPanel extends StatefulWidget {
  const AdminSimpleExclusiveDealsPanel({super.key, required this.service});

  final FirestoreCatalogService service;

  @override
  State<AdminSimpleExclusiveDealsPanel> createState() =>
      _AdminSimpleExclusiveDealsPanelState();
}

class _AdminSimpleExclusiveDealsPanelState
    extends State<AdminSimpleExclusiveDealsPanel> {
  User? get _actor => FirebaseAuth.instance.currentUser;

  bool _isSyncing = false;

  Future<void> _syncDcmOffers() async {
    setState(() => _isSyncing = true);
    try {
      final dcmService = DcmNetworkService();
      final offers = await dcmService.fetchLatestOffers();
      
      int count = 0;
      for (final deal in offers) {
        await widget.service.saveExclusiveDeal(
          deal,
          editorUserId: _actor?.uid,
          editorEmail: _actor?.email,
        );
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('تمت مزامنة $count عرضاً من DCM بنجاح.', 'Synced $count offers from DCM successfully.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('خطأ في المزامنة: $e', 'Sync error: $e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _add() async {
    final deal = await showDialog<ExclusiveDeal>(
      context: context,
      builder: (_) => const AdminExclusiveDealEditorDialog(),
    );
    if (deal == null || !mounted) return;
    try {
      await widget.service.saveExclusiveDeal(
        deal,
        editorUserId: _actor?.uid,
        editorEmail: _actor?.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('تمت إضافة العرض بنجاح.', 'Deal added successfully.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))),
        );
      }
    }
  }

  Future<void> _edit(ExclusiveDeal deal) async {
    final updated = await showDialog<ExclusiveDeal>(
      context: context,
      builder: (_) => AdminExclusiveDealEditorDialog(initialDeal: deal),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.service.saveExclusiveDeal(
        updated,
        editorUserId: _actor?.uid,
        editorEmail: _actor?.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('تم تحديث العرض بنجاح.', 'Deal updated successfully.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))),
        );
      }
    }
  }

  Future<void> _publish(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) return;
    try {
      await widget.service.publishExclusiveDeal(
        deal.id,
        editorUserId: _actor?.uid,
        editorEmail: _actor?.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('تم نشر العرض بنجاح.', 'Deal published successfully.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))),
        );
      }
    }
  }

  Future<void> _delete(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('حذف العرض', 'Delete deal')),
            content: Text(
              tr(
                'هل تريد حذف "${deal.title}"؟',
                'Do you want to delete "${deal.title}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteExclusiveDeal(deal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم حذف العرض.', 'Deal deleted.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))),
        );
      }
    }
  }

  Widget _buildDealCard(ExclusiveDeal deal) {
    final expired = deal.isExpired;
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            deal.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.local_offer_rounded),
          ),
        ),
        title: Text(
          deal.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${deal.beforePrice > 0 ? '${formatPrice(deal.beforePrice)} ${tr('ريال', 'SAR')}' : ''}'
          '${deal.phone.trim().isNotEmpty ? '\n📞 ${deal.phone}' : ''}'
          '${expired ? '\n${tr('منتهي', 'Expired')}' : ''}'
          '${deal.createdByEmail.trim().isNotEmpty ? '\n${tr('بواسطة', 'By')}: ${deal.createdByEmail}' : ''}',
        ),
        isThreeLine: deal.phone.trim().isNotEmpty || deal.createdByEmail.trim().isNotEmpty,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: tr('تعديل', 'Edit'),
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _edit(deal),
            ),
            IconButton(
              tooltip: tr('نشر', 'Publish'),
              icon: const Icon(Icons.publish_rounded),
              onPressed: () => _publish(deal),
            ),
            IconButton(
              tooltip: tr('حذف', 'Delete'),
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () => _delete(deal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      body: StreamBuilder<List<ExclusiveDeal>>(
        stream: widget.service.watchAdminExclusiveDeals(),
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final deals = snap.data ?? const <ExclusiveDeal>[];

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
                      'العروض الحصرية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSyncing)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: _syncDcmOffers,
                            icon: const Icon(Icons.sync_rounded),
                            label: Text(tr('مزامنة DCM', 'Sync DCM')),
                          ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(tr('إضافة عرض', 'Add deal')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr('خطأ: ${snap.error}', 'Error: ${snap.error}'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (deals.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      tr(
                        'لا توجد عروض بعد. أضف أول عرض الآن.',
                        'No deals yet. Add the first one now.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF6B7A9A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: deals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildDealCard(deals[i]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('إضافة عرض', 'Add deal')),
      ),
    );
  }
}
