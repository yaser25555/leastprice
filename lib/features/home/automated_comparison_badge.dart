import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AutomatedComparisonBadge extends StatelessWidget {
  const AutomatedComparisonBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: AppPalette.comparisonSoftEmerald,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.comparisonBorder),
      ),
      child: Text(
        tr('محدث آلياً', 'Auto-updated'),
        style: TextStyle(
          color: AppPalette.comparisonEmerald,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
