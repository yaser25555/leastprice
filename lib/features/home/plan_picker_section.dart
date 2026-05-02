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
          tr('كوبونات خصم حصرية من أمازون ونون ونمشي وغيرها',
              'Exclusive discount coupons from Amazon, Noon, Namshi & more'),
          tr('أولوية في الدعم بعد التحويل', 'Priority support after transfer'),
          tr('إشعارات فورية للعروض السريعة (اللقطات)', 'Instant notifications for quick deals (steals)'),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.cardBorder, width: 1.4),
        boxShadow: [
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppPalette.gradientWarmCta,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.orangeCrimson.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppPalette.pureWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('اختر باقتك', 'Choose your plan'),
                  style: TextStyle(
                    color: AppPalette.panelText,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (widget.isPaidActive)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppPalette.gradientWarmCta,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.orangeCrimson.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    tr('مفعلة', 'Active'),
                    style: TextStyle(
                      color: AppPalette.pureWhite,
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
              final isYearly = tier == LeastPricePlanTier.yearly;
              return InkWell(
                onTap: () => setState(() => _selected = tier),
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 165,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? null : AppPalette.softNavy,
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppPalette.deepNavy,
                                  AppPalette.orangeCrimson.withValues(alpha: 0.35),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppPalette.orangeWarm
                              : AppPalette.cardBorder,
                          width: isSelected ? 1.8 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppPalette.orangeCrimson
                                      .withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : const [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tierTitle(tier),
                            style: TextStyle(
                              color: AppPalette.panelText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ShaderMask(
                            shaderCallback: (rect) =>
                                AppPalette.gradientWarmCta.createShader(rect),
                            child: Text(
                              _tierPrice(tier),
                              style: TextStyle(
                                color: AppPalette.pureWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isYearly)
                      Positioned(
                        top: -8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppPalette.gradientWarmCta,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.orangeCrimson
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            tr('أفضل قيمة', 'Best value'),
                            style: TextStyle(
                              color: AppPalette.pureWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: EdgeInsets.all(14),
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
                  style: TextStyle(
                    color: AppPalette.panelText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ..._tierBenefits(_selected).asMap().entries.map((entry) {
                  final index = entry.key;
                  final line = entry.value;
                  // Rotate accent colors so the list breathes beyond a single tone.
                  final accents = <Color>[
                    AppPalette.orangeWarm,
                    AppPalette.orangeCoral,
                    AppPalette.accentSky,
                    AppPalette.orangeCrimson,
                  ];
                  final accent = accents[index % accents.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              color: AppPalette.mutedText,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (selectedIsPaid) ...[
            const SizedBox(height: 14),
            Container(
              padding: EdgeInsets.all(14),
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
                    style: TextStyle(
                      color: AppPalette.pureWhite,
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
                    style: TextStyle(
                      color: AppPalette.pureWhite.withValues(alpha: 0.85),
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
                          foregroundColor: AppPalette.pureWhite,
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
                    style: TextStyle(
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

