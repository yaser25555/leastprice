import 'package:flutter/material.dart';

import 'package:leastprice/core/utils/helpers.dart';

class LeastPriceScrollBehavior extends MaterialScrollBehavior {
  const LeastPriceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (isAppleInterface(context)) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }

    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
