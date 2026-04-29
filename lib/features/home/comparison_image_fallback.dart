import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';

class ComparisonImageFallback extends StatelessWidget {
  const ComparisonImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      color: AppPalette.cardBackground,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_search_rounded,
        color: AppPalette.softNavy,
        size: 34,
      ),
    );
  }
}
