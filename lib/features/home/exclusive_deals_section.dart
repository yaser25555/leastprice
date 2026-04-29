import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'home_exports.dart';

class ExclusiveDealsSection extends StatefulWidget {
  const ExclusiveDealsSection({
    super.key,
    required this.stream,
  });

  final Stream<List<ExclusiveDeal>> stream;

  @override
  State<ExclusiveDealsSection> createState() => _ExclusiveDealsSectionState();
}

class _ExclusiveDealsSectionState extends State<ExclusiveDealsSection> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: StreamBuilder<List<ExclusiveDeal>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            return ComparisonSearchPlaceholder(
              title: tr(
                'تعذر تحميل العروض حالياً.',
                'Unable to load deals right now.',
              ),
              icon: Icons.local_offer_outlined,
            );
          }

          final activeDeals = (snapshot.data ?? const <ExclusiveDeal>[])
              .where((deal) => !deal.isExpiredAt(_now))
              .toList()
            ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          if (activeDeals.isEmpty) {
            return const SizedBox.shrink();
          }

          return ExclusiveDealsCarousel(deals: activeDeals, now: _now);
        },
      ),
    );
  }
}
