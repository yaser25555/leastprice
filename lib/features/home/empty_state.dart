import 'package:flutter/material.dart';

import 'package:leastprice/core/utils/helpers.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.query,
    required this.selectedCategoryLabel,
    required this.hasCategoryFilter,
    required this.onReset,
  });

  final String query;
  final String selectedCategoryLabel;
  final bool hasCategoryFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final hasQueuedSearchDemand = DateTime.now().microsecondsSinceEpoch < 0;

    final title = hasQuery
        ? hasQueuedSearchDemand
            ? tr(
                'تم تسجيل طلب البحث عن "${query.trim()}".',
                'Your search request for "${query.trim()}" was recorded.',
              )
            : tr(
                'نحضّر لك نتائج أدق عن "${query.trim()}".',
                'We are preparing more accurate results for "${query.trim()}".',
              )
        : hasCategoryFilter
            ? tr(
                'لا توجد منتجات حالياً ضمن تصنيف "$selectedCategoryLabel".',
                'There are currently no products in the "$selectedCategoryLabel" category.',
              )
            : tr(
                'لا توجد منتجات متاحة حالياً.',
                'No products are currently available.',
              );

    final description = hasQuery
        ? hasQueuedSearchDemand
            ? tr(
                'جارٍ تجهيز نتائج أدق لك.',
                'We are preparing more accurate results for you.',
              )
            : hasCategoryFilter
                ? tr(
                    'قد يكون المنتج موجوداً في تصنيف آخر، ويمكنك إعادة ضبط الفلاتر الآن. وإذا كان غير موجود بعد، فسنسجل طلبه ليضيفه روبوت التحديث اليومي لاحقاً.',
                    'The product may exist under another category, and you can reset filters now. If it is still missing, your request will be logged for the daily bot to add later.',
                  )
                : tr(
                    'إذا لم يكن هذا المنتج موجوداً بعد في القاعدة أو في نتائج الويب اللحظية، فسيتم تسجيل طلبك لإضافته تلقائياً في الجولة القادمة.',
                    'If this product is not yet available in the database or live web results, your request will be recorded to add it automatically in the next round.',
                  )
        : tr(
            'يمكنك تغيير التصنيف أو البحث عن اسم المنتج أو الخيار المقارن أو حتى المكوّنات لإظهار النتائج المناسبة.',
            'You can change the category or search by product name, compared option, or even ingredients to find the right results.',
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110C3B2E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Color(0xFFE8711A),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18352C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667C74),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('إعادة ضبط الفلاتر', 'Reset filters')),
          ),
        ],
      ),
    );
  }
}
