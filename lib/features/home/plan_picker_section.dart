import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

enum LeastPricePlanTier {
  free,
  monthly,
  yearly,
}

class PlanPickerSection extends StatefulWidget {
  const PlanPickerSection({
    super.key,
    required this.isPaidActive,
    required this.visibleResultsCount,
    required this.onWhatsAppTap,
  });

  final bool isPaidActive;
  final int visibleResultsCount;
  final VoidCallback onWhatsAppTap;

  @override
  State<PlanPickerSection> createState() => _PlanPickerSectionState();
}

class _PlanPickerSectionState extends State<PlanPickerSection> {
  LeastPricePlanTier _selected = LeastPricePlanTier.free;

  @override
  void initState() {
    super.initState();
    if (widget.isPaidActive) {
      _selected = LeastPricePlanTier.yearly;
    }
  }

  String _tierTitle(LeastPricePlanTier tier) {
    switch (tier) {
      case LeastPricePlanTier.free:
        return tr('مجانية', 'Free');
      case LeastPricePlanTier.monthly:
        return tr('شهرية', 'Monthly');
      case LeastPricePlanTier.yearly:
        return tr('سنوية', 'Yearly');
    }
  }

  String _tierPrice(LeastPricePlanTier tier) {
    switch (tier) {
      case LeastPricePlanTier.free:
        return tr('0 ر.س', 'SAR 0');
      case LeastPricePlanTier.monthly:
        return tr('9.99 ر.س', 'SAR 9.99');
      case LeastPricePlanTier.yearly:
        return tr('79.99 ر.س', 'SAR 79.99');
    }
  }

  List<String> _tierBenefits(LeastPricePlanTier tier) {
    switch (tier) {
      case LeastPricePlanTier.free:
        return [
          tr('عرض أول ${widget.visibleResultsCount} نتائج فقط', 'Shows only the first ${widget.visibleResultsCount} results'),
          tr('اختيار المدينة يدويًا', 'Manual city selection'),
          tr('دعم أساسي', 'Basic support'),
        ];
      case LeastPricePlanTier.monthly:
      case LeastPricePlanTier.yearly:
        return [
          tr('عرض جميع النتائج بدون حد', 'Unlimited full results'),
          tr('فتح جميع ميزات البحث والمقارنة', 'Unlock all search & comparison features'),
          tr('أولوية في الدعم بعد التحويل', 'Priority support after transfer'),
        ];
    }
  }

  Future<void> _copyIban() async {
    await Clipboard.setData(
      const ClipboardData(text: 'SA7005000068202380361000'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('تم نسخ الآيبان.', 'IBAN copied.')),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    // Prefer existing app flow: delegate to caller when possible.
    widget.onWhatsAppTap();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIsPaid = _selected != LeastPricePlanTier.free;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.cardBorder, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.deepNavy,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cardBorder),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppPalette.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('اختر باقتك', 'Choose your plan'),
                  style: const TextStyle(
                    color: AppPalette.panelText,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (widget.isPaidActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.deepNavy,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppPalette.cardBorder),
                  ),
                  child: Text(
                    tr('مفعلة', 'Active'),
                    style: const TextStyle(
                      color: AppPalette.orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: LeastPricePlanTier.values.map((tier) {
              final isSelected = _selected == tier;
              return InkWell(
                onTap: () => setState(() => _selected = tier),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 165,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppPalette.deepNavy : AppPalette.softNavy,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppPalette.orange : AppPalette.cardBorder,
                      width: isSelected ? 1.8 : 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tierTitle(tier),
                        style: const TextStyle(
                          color: AppPalette.panelText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tierPrice(tier),
                        style: const TextStyle(
                          color: AppPalette.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.deepNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('الفرق بين الباقات', 'Plan differences'),
                  style: const TextStyle(
                    color: AppPalette.panelText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ..._tierBenefits(_selected).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppPalette.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppPalette.mutedText,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedIsPaid) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.softNavy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppPalette.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('معلومات التحويل', 'Transfer details'),
                    style: const TextStyle(
                      color: AppPalette.panelText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'بنك الإنماء — باسم: ناصر فاهد الزعبي\n'
                      'الآيبان: SA7005000068202380361000\n'
                      'بعد التحويل يتم تفعيل الخطة يدويًا.',
                      'Bank Alinma — Name: Nasser Fahed Alzaabi\n'
                      'IBAN: SA7005000068202380361000\n'
                      'Plan activation is done manually after transfer.',
                    ),
                    style: const TextStyle(
                      color: AppPalette.mutedText,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyIban,
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(tr('نسخ الآيبان', 'Copy IBAN')),
                      ),
                      FilledButton.icon(
                        onPressed: _openWhatsApp,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.forum_rounded),
                        label: Text(
                          tr('واتساب: اتصل بنا بعد التحويل',
                              'WhatsApp: Contact after transfer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'رقم الدعم: 00966558570889',
                      'Support: 00966558570889',
                    ),
                    style: const TextStyle(
                      color: AppPalette.paleOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

