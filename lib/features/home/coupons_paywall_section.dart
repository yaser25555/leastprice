import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class CouponsPaywallSection extends StatelessWidget {
  const CouponsPaywallSection({
    super.key,
    required this.onUpgradeTap,
    this.couponCount = 0,
  });

  final VoidCallback onUpgradeTap;
  final int couponCount;

  static List<_PaywallStore> get _featuredStores => [
        _PaywallStore('Amazon', Color(0xFFFF9900), Color(0xFF232F3E)),
        _PaywallStore('Noon', Color(0xFFFEEE00), Color(0xFF1F1F1F)),
        _PaywallStore('Namshi', Color(0xFF7E3CC0), AppPalette.pureWhite),
        _PaywallStore('SHEIN', Color(0xFF222222), AppPalette.pureWhite),
        _PaywallStore('iHerb', Color(0xFF4FA72E), AppPalette.pureWhite),
        _PaywallStore('Sephora', Color(0xFF111111), AppPalette.pureWhite),
        _PaywallStore('Jarir', Color(0xFFC62828), AppPalette.pureWhite),
        _PaywallStore('Extra', Color(0xFF00695C), AppPalette.pureWhite),
        _PaywallStore('Panda', Color(0xFF2E7D32), AppPalette.pureWhite),
        _PaywallStore('Othaim', Color(0xFF1565C0), AppPalette.pureWhite),
        _PaywallStore('Tamimi', Color(0xFFE65100), AppPalette.pureWhite),
        _PaywallStore('Nahdi', Color(0xFF0D47A1), AppPalette.pureWhite),
        _PaywallStore('Al-Dawaa', Color(0xFF1B5E20), AppPalette.pureWhite),
        _PaywallStore('Lulu', Color(0xFFD32F2F), AppPalette.pureWhite),
        _PaywallStore('Carrefour', Color(0xFF004D99), AppPalette.pureWhite),
        _PaywallStore('Nike', Colors.black, AppPalette.pureWhite),
        _PaywallStore('Adidas', Color(0xFF000000), AppPalette.pureWhite),
        _PaywallStore('H&M', Color(0xFFCF1126), AppPalette.pureWhite),
        _PaywallStore('Sun & Sand', Color(0xFFE30613), AppPalette.pureWhite),
        _PaywallStore('Huda Beauty', Color(0xFF231F20), AppPalette.pureWhite),
        _PaywallStore('Under Armour', Color(0xFF1D1D1D), AppPalette.pureWhite),
        _PaywallStore('Puma', Color(0xFFBA0C2F), AppPalette.pureWhite),
        _PaywallStore('Natural Touch', Color(0xFF1B5E20), AppPalette.pureWhite),
        _PaywallStore('Itsmine', Color(0xFFD81B60), AppPalette.pureWhite),
        _PaywallStore('لمعة اللؤلؤة', Color(0xFFB8860B), AppPalette.pureWhite),
        _PaywallStore('الغربي', Color(0xFF5D4037), AppPalette.pureWhite),
        _PaywallStore('مشكاة مران', Color(0xFF558B2F), AppPalette.pureWhite),
        _PaywallStore('الحواج', Color(0xFFBF360C), AppPalette.pureWhite),
        _PaywallStore('ثلاث أرباع', Color(0xFF1565C0), AppPalette.pureWhite),
        _PaywallStore('SWANKY', Color(0xFF4E342E), AppPalette.pureWhite),
        _PaywallStore('Shaving360', Color(0xFF263238), AppPalette.pureWhite),
        _PaywallStore('ليدرز', Color(0xFF1565C0), AppPalette.pureWhite),
        _PaywallStore('سمارت هب 1', Color(0xFF00838F), AppPalette.pureWhite),
        _PaywallStore('RAG Roastery', Color(0xFF6D4C41), AppPalette.pureWhite),
        _PaywallStore('ركله', Color(0xFF1A237E), AppPalette.pureWhite),
        _PaywallStore('Burgundy', Color(0xFF800020), AppPalette.pureWhite),
        _PaywallStore('Take Card', Color(0xFF00ACC1), AppPalette.pureWhite),
        _PaywallStore('سدا كاردز', Color(0xFFE65100), AppPalette.pureWhite),
        _PaywallStore('العنود للأزياء', Color(0xFFD81B60), AppPalette.pureWhite),
        _PaywallStore('Her Fitness', Color(0xFF2E7D32), AppPalette.pureWhite),
        _PaywallStore('E-SEVEN', Color(0xFF37474F), AppPalette.pureWhite),
        _PaywallStore('كوزمازون', Color(0xFFAD1457), AppPalette.pureWhite),
        _PaywallStore('عالم الشواء', Color(0xFFBF360C), AppPalette.pureWhite),
        _PaywallStore('فريسيا', Color(0xFF8E24AA), AppPalette.pureWhite),
        _PaywallStore('كلمنتان', Color(0xFF4E342E), AppPalette.pureWhite),
        _PaywallStore('عالم جيفنشي', Color(0xFF1A237E), AppPalette.pureWhite),
        _PaywallStore('بكم', Color(0xFF1565C0), AppPalette.pureWhite),
        _PaywallStore('ريتسكين', Color(0xFFC2185B), AppPalette.pureWhite),
        _PaywallStore('ماضي الطيب', Color(0xFF5D4037), AppPalette.pureWhite),
        _PaywallStore('مارسيل', Color(0xFFE91E63), AppPalette.pureWhite),
        _PaywallStore('المختص', Color(0xFFE53935), AppPalette.pureWhite),
        _PaywallStore('ملاي', Color(0xFF7B1FA2), AppPalette.pureWhite),
      ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        padding: EdgeInsets.all(18),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppPalette.accentSkyPale,
                    AppPalette.accentSky,
                    AppPalette.accentSkyDeep,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.accentSky.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                color: AppPalette.pureWhite,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                key: const ValueKey('coupons_text'),
                couponCount > 0
                    ? tr(
                        'العديد من الكوبونات بنسب خصم مذهلة',
                        'Many coupons with amazing discounts',
                      )
                    : tr(
                        'كوبونات حصرية في انتظارك',
                        'Exclusive coupons waiting for you',
                      ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppPalette.panelText,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'اشترك لفتح أكواد خصم محدّثة من أشهر المتاجر السعودية والعالمية.',
                'Subscribe to unlock fresh discount codes from top Saudi and global stores.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 4;
                const spacing = 10.0;
                final chipWidth =
                    (constraints.maxWidth - (columns - 1) * spacing) / columns;
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spacing,
                  runSpacing: 10,
                  children: _featuredStores
                      .map((store) => SizedBox(
                            width: chipWidth,
                            child: _StoreChip(store: store),
                          ))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 18),
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
                  _BenefitRow(
                    accent: AppPalette.orangeWarm,
                    label: tr('أكواد خصم محدّثة أسبوعيًا',
                        'Fresh discount codes weekly'),
                  ),
                  SizedBox(height: 8),
                  _BenefitRow(
                    accent: AppPalette.accentSky,
                    label: tr('من أمازون ونون ونمشي وغيرها',
                        'From Amazon, Noon, Namshi & more'),
                  ),
                  SizedBox(height: 8),
                  _BenefitRow(
                    accent: AppPalette.orangeCoral,
                    label: tr('نسخ الكود بضغطة واحدة', 'One-tap code copy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppPalette.gradientWarmCta,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.orangeCrimson.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onUpgradeTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            color: AppPalette.pureWhite,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tr('اشترك الآن لفتح الكوبونات',
                                'Subscribe now to unlock coupons'),
                            style: TextStyle(
                              color: AppPalette.pureWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('ابتداءً من 9.99 ر.س / شهريًا',
                  'Starting from SAR 9.99 / month'),
              style: TextStyle(
                color: AppPalette.paleOrange,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallStore {
  const _PaywallStore(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.store});

  final _PaywallStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: store.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            store.label,
            style: TextStyle(
              color: store.foreground,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: accent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppPalette.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
