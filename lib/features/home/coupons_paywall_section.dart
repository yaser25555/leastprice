import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class CouponsPaywallSection extends StatelessWidget {
  const CouponsPaywallSection({
    super.key,
    required this.onUpgradeTap,
  });

  final VoidCallback onUpgradeTap;

  static const List<_PaywallStore> _featuredStores = [
    _PaywallStore('Amazon', Color(0xFFFF9900), Color(0xFF232F3E)),
    _PaywallStore('Noon', Color(0xFFFEEE00), Color(0xFF1F1F1F)),
    _PaywallStore('Namshi', Color(0xFF7E3CC0), Colors.white),
    _PaywallStore('iHerb', Color(0xFF4FA72E), Colors.white),
    _PaywallStore('Sephora', Color(0xFF111111), Colors.white),
    _PaywallStore('SHEIN', Color(0xFF222222), Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(18),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
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
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr(
                'كوبونات حصرية في انتظارك',
                'Exclusive coupons waiting for you',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppPalette.panelText,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'اشترك لفتح أكواد خصم محدّثة من أشهر المتاجر السعودية والعالمية.',
                'Subscribe to unlock fresh discount codes from top Saudi and global stores.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: _featuredStores
                  .map((store) => _StoreChip(store: store))
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
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
                  _BenefitRow(
                    accent: AppPalette.orangeWarm,
                    label: tr('أكواد خصم محدّثة أسبوعيًا',
                        'Fresh discount codes weekly'),
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    accent: AppPalette.accentSky,
                    label: tr('من أمازون ونون ونمشي وغيرها',
                        'From Amazon, Noon, Namshi & more'),
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    accent: AppPalette.orangeCoral,
                    label: tr('نسخ الكود بضغطة واحدة',
                        'One-tap code copy'),
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
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tr('اشترك الآن لفتح الكوبونات',
                                'Subscribe now to unlock coupons'),
                            style: const TextStyle(
                              color: Colors.white,
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
              style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: store.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Text(
        store.label,
        style: TextStyle(
          color: store.foreground,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.4,
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
            style: const TextStyle(
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

