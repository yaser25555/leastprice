import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SavingBadge extends StatelessWidget {
  const SavingBadge({super.key, required this.savingsPercent});

  final int savingsPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.comparisonEmerald, Color(0xFF16AA83)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tr('وفرت $savingsPercent%', 'Saved $savingsPercent%'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SuperSavingBadge extends StatelessWidget {
  const SuperSavingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0C56B)),
      ),
      child: Text(
        tr('توفير خارق', 'Super saving'),
        style: const TextStyle(
          color: Color(0xFF9A6700),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class OriginalOnSaleBadge extends StatelessWidget {
  const OriginalOnSaleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA6D0F2)),
      ),
      child: Text(
        tr(
          'المنتج الأصلي عليه عرض حالياً',
          'Original product is on sale now',
        ),
        style: const TextStyle(
          color: Color(0xFF185A8B),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
