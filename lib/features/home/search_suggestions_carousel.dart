import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SearchSuggestionsCarousel extends StatefulWidget {
  const SearchSuggestionsCarousel({super.key});

  @override
  State<SearchSuggestionsCarousel> createState() =>
      _SearchSuggestionsCarouselState();
}

class _SearchSuggestionsCarouselState extends State<SearchSuggestionsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'الإلكترونيات والجوالات',
      'subtitle':
          'قارن أسعار الهواتف الذكية، الحواسيب، والإلكترونيات الاستهلاكية لتجد أفضل الصفقات.',
      'icon': Icons.devices_rounded,
      'gradient': const [Color(0xFF5E72E4), Color(0xFF825EE4)],
    },
    {
      'title': 'المواد الغذائية والسوبرماركت',
      'subtitle':
          'ابحث عن منتجات البقالة اليومية والمواد الغذائية لتوفير المزيد في ميزانيتك.',
      'icon': Icons.shopping_basket_rounded,
      'gradient': const [Color(0xFF2DCE89), Color(0xFF2DCECC)],
    },
    {
      'title': 'المطاعم والمقاهي',
      'subtitle': 'أفضل عروض الوجبات، القهوة، والمطاعم من حولك بأقل الأسعار.',
      'icon': Icons.restaurant_rounded,
      'gradient': [AppPalette.orange, Color(0xFFFF7A00)],
    },
    {
      'title': 'العطور والتجميل',
      'subtitle':
          'تشكيلة واسعة من العطور ومستحضرات التجميل مع مقارنة دقيقة للأسعار.',
      'icon': Icons.face_retouching_natural_rounded,
      'gradient': const [Color(0xFFF5365C), Color(0xFFF56036)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= _suggestions.length) {
          _currentPage = 0;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppPalette.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                tr('اكتشف أفضل الصفقات', 'Discover top deals'),
                style: TextStyle(
                  color: AppPalette.panelText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final item = _suggestions[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 160,
                      width: double.infinity,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item['gradient'] as List<Color>,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (item['gradient'] as List<Color>)[0]
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          item['icon'] as IconData,
                          size: 100,
                          color: AppPalette.pureWhite.withOpacity(0.15),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppPalette.pureWhite.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: AppPalette.pureWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    color: AppPalette.pureWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              color: AppPalette.pureWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
