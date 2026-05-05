import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/features/home/exclusive_deal_card.dart';
import 'home_exports.dart';

class ExclusiveDealsCarousel extends StatefulWidget {
  const ExclusiveDealsCarousel({
    super.key,
    required this.deals,
    required this.now,
  });

  final List<ExclusiveDeal> deals;
  final DateTime now;

  @override
  State<ExclusiveDealsCarousel> createState() => _ExclusiveDealsCarouselState();
}

class _ExclusiveDealsCarouselState extends State<ExclusiveDealsCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant ExclusiveDealsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deals.length != widget.deals.length) {
      _autoPlayTimer?.cancel();
      _currentIndex = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.deals.length <= 1) {
      return;
    }

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % widget.deals.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.deals.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final deal = widget.deals[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: ExclusiveDealCard(
                  deal: deal,
                  now: widget.now,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.deals.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? AppPalette.dealsRed : AppPalette.dealsBorder,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}
