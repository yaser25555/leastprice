import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/models/automation_health_status.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/cart/shopping_cart_screen.dart';
import 'package:leastprice/providers/shopping_cart_provider.dart';
import 'package:leastprice/features/admin/admin_exports.dart';
import 'home_exports.dart';
import 'package:leastprice/features/home/home_search_provider.dart';
import 'package:leastprice/features/home/home_search_view.dart';
import 'package:leastprice/features/home/home_connectivity_provider.dart';
import 'package:leastprice/features/home/home_data_providers.dart';
import 'package:leastprice/features/home/home_page_actions.dart';
import 'package:leastprice/features/home/product_detail_screen.dart';
import 'package:leastprice/features/home/favorites_screen.dart';
import 'package:leastprice/features/search/barcode_scanner_screen.dart';
import 'package:leastprice/services/api/open_food_facts_service.dart';
import 'package:leastprice/services/notifications/push_notification_service.dart';

class LeastPriceHomePage extends ConsumerStatefulWidget {
  const LeastPriceHomePage({
    super.key,
    required this.firebaseReady,
    required this.currentUser,
    required this.initialUserProfile,
    this.bootstrapNotice,
  });

  final bool firebaseReady;
  final User currentUser;
  final UserSavingsProfile initialUserProfile;
  final String? bootstrapNotice;

  @override
  ConsumerState<LeastPriceHomePage> createState() => _LeastPriceHomePageState();
}

class _LeastPriceHomePageState extends ConsumerState<LeastPriceHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final HomePageActions _actions = const HomePageActions();
  final FirestoreCatalogService _catalogService =
      const FirestoreCatalogService();

  HomeCatalogSection _selectedHomeSection = HomeCatalogSection.comparisons;
  bool _isRefreshing = false;
  bool _isDetectingCity = false;

  static const int _trialVisibleResultsCount = 5;

  bool get _isPrimaryAdmin =>
      (widget.currentUser.email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_detectCityFromCurrentLocation(showFeedback: false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshCatalog(showSuccessMessage: false));
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectCityFromCurrentLocation({
    bool showFeedback = true,
  }) async {
    if (_isDetectingCity || !mounted) return;

    setState(() => _isDetectingCity = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'خدمة الموقع غير مفعلة. فعّل GPS ثم حاول مرة أخرى.',
                  'Location services are disabled. Enable GPS and try again.',
                ),
              ),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'تم رفض إذن الموقع. يمكنك اختيار المدينة يدويًا.',
                  'Location permission was denied. You can choose the city manually.',
                ),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return;

      final cityTokens = <String>[
        placemarks.first.locality ?? '',
        placemarks.first.subAdministrativeArea ?? '',
        placemarks.first.administrativeArea ?? '',
      ].map(normalizeArabic).where((value) => value.isNotEmpty).toList();

      MarketplaceSearchCity? detectedCity;
      for (final city in marketplaceSearchCities) {
        final cityLabel = normalizeArabic(city.arLabel);
        final cityLabelEn = normalizeArabic(city.enLabel);
        final cityId = normalizeArabic(city.id.replaceAll('_', ' '));
        final isMatch = cityTokens.any(
          (token) =>
              token.contains(cityLabel) ||
              cityLabel.contains(token) ||
              token.contains(cityLabelEn) ||
              token.contains(cityId),
        );
        if (isMatch) {
          detectedCity = city;
          break;
        }
      }

      if (detectedCity == null) return;
      if (!mounted) return;

      ref.read(homeSearchProvider.notifier).setCity(detectedCity);
      final query = ref.read(homeSearchProvider).query;
      final hasInternet = ref.read(connectivityProvider).value ?? true;
      if (query.trim().isNotEmpty && hasInternet) {
        await ref
            .read(homeSearchProvider.notifier)
            .performSearch(forceRefresh: true);
      }

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم تحديد المدينة تلقائيًا: ${detectedCity.label}',
                'City detected automatically: ${detectedCity.label}',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تعذر تحديد المدينة تلقائيًا الآن. اختر المدينة يدويًا.',
                'Unable to detect city automatically right now. Choose city manually.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingCity = false);
    }
  }

  void _openBarcodeScanner(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (barcode == null || barcode.isEmpty || !context.mounted) return;

    final productName = await OpenFoodFactsService.getProductNameFromBarcode(barcode);
    if (productName != null && productName.isNotEmpty && context.mounted) {
      _searchController.text = productName;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: productName.length),
      );
      final notifier = ref.read(homeSearchProvider.notifier);
      notifier.setQuery(productName);
      notifier.performSearch(forceRefresh: true);
      _searchFocusNode.unfocus();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'لم نتعرف على المنتج. جرّب البحث يدوياً.',
            'Product not found. Try searching manually.',
          )),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPriceFilter(BuildContext context) {
    final notifier = ref.read(homeSearchProvider.notifier);
    final state = ref.read(homeSearchProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PriceFilterSheet(
        minPrice: state.filterMinPrice,
        maxPrice: state.filterMaxPrice,
        onApply: (min, max) {
          notifier.setPriceFilter(min, max);
          Navigator.pop(ctx);
        },
        onClear: () {
          notifier.clearFilters();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _selectHomeSection(HomeCatalogSection section) {
    if (_selectedHomeSection == section) return;
    setState(() => _selectedHomeSection = section);
  }

  Future<void> _refreshCatalog({bool showSuccessMessage = true}) async {
    if (!widget.firebaseReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'أكمل إعداد Firebase أولاً حتى يتمكن التطبيق من التحديث من Cloud Firestore.',
              'Complete the Firebase setup first so the app can refresh from Cloud Firestore.',
            ),
          ),
        ),
      );
      return;
    }

    final hasInternet = ref.read(connectivityProvider).value ?? true;
    if (!hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'لا يوجد اتصال حالياً. سنعرض آخر البيانات المتاحة حتى تعود الشبكة.',
              'There is no connection right now. We will keep showing the latest available data until the network returns.',
            ),
          ),
        ),
      );
      return;
    }

    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _catalogService.refreshProductsFromServer();
      if (ref.read(homeSearchProvider).query.trim().isNotEmpty) {
        await ref
            .read(homeSearchProvider.notifier)
            .performSearch(forceRefresh: true);
      }
      if (!mounted) return;

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم تحديث قائمة المنتجات من الإنترنت بنجاح.',
                'Product list updated successfully from the internet.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر الوصول إلى قاعدة البيانات حالياً. تحقق من الاتصال ثم أعد السحب.',
              'Unable to reach the database right now. Check your connection, then pull to refresh again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showFirebaseSetupRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'التطبيق يحتاج تهيئة Firebase وCloud Firestore أولاً قبل استخدام قاعدة البيانات.',
            'The app needs Firebase and Cloud Firestore setup before using the database.',
          ),
        ),
      ),
    );
  }

  void _handleConnectivityChange(bool hasInternet, BuildContext context) {
    if (hasInternet) {
      unawaited(_refreshCatalog(showSuccessMessage: false));
      final query = ref.read(homeSearchProvider).query;
      if (query.trim().isNotEmpty) {
        unawaited(ref.read(homeSearchProvider.notifier).performSearch());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('تمت استعادة الاتصال بالشبكة.', 'Connection restored.'),
          ),
        ),
      );
    } else {
      ref.read(homeSearchProvider.notifier).clearSearch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('لا يوجد اتصال بالإنترنت حالياً.',
                'No internet connection right now.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInternet = ref.watch(connectivityProvider).value ?? true;
    final userProfileAsync = ref.watch(
        userProfileStreamProvider(widget.currentUser.uid));
    final activeBannersAsync = ref.watch(adBannersStreamProvider);
    final systemHealthAsync = ref.watch(systemHealthStreamProvider);

    final userProfile = userProfileAsync.value ?? widget.initialUserProfile;
    final activeBanners =
        activeBannersAsync.value ?? AdBannerItem.mockData;
    final systemHealth = systemHealthAsync.value ?? AutomationHealthStatus.initial();

    final isPaidPlanActive = userProfile.planActivated;
    final canAccessAdminPanel =
        _isPrimaryAdmin || userProfile.isMarketingManager;

    if (userProfileAsync.hasError && mounted) {
      PushNotificationService.updatePremiumSubscription(userProfile);
    }

    if (ref.read(connectivityProvider).value != hasInternet &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleConnectivityChange(hasInternet, context);
        }
      });
    }

    return Scaffold(
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final cartItems = ref.watch(shoppingCartProvider);
          final showAdminFab = canAccessAdminPanel;
          final showCartFab = cartItems.isNotEmpty;

          if (!showAdminFab && !showCartFab) return const SizedBox.shrink();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'favorites-fab',
                tooltip: tr('المفضلة', 'Favorites'),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
                child: const Icon(Icons.favorite, size: 20),
              ),
              const SizedBox(height: 12),
              if (showAdminFab)
                FloatingActionButton.small(
                  heroTag: 'admin-dashboard-fab',
                  tooltip: tr('لوحة المسؤول', 'Admin panel'),
                  backgroundColor: AppPalette.navy,
                  foregroundColor: AppPalette.pureWhite,
                  onPressed: widget.firebaseReady
                      ? () async {
                          final allowed = await _actions
                              .verifyLocalAdminPassword(context);
                          if (!allowed || !context.mounted) return;
                          await Future<void>.delayed(
                              const Duration(milliseconds: 16));
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminControlCenter(
                                  adminUser: widget.currentUser),
                            ),
                          );
                        }
                      : _showFirebaseSetupRequired,
                  child: const Icon(Icons.admin_panel_settings_rounded),
                ),
              if (showAdminFab && showCartFab) const SizedBox(height: 12),
              if (showCartFab)
                FloatingActionButton.extended(
                  heroTag: 'shopping-cart-fab',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ShoppingCartScreen()),
                    );
                  },
                  backgroundColor: AppPalette.orange,
                  icon: const Icon(Icons.shopping_cart_checkout_rounded,
                      color: Colors.white),
                  label: Text(
                    '${cartItems.length} منتجات',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        },
      ),
      body: StreamBuilder<List<ProductComparison>>(
        stream: widget.firebaseReady
            ? ref.watch(productsStreamProvider).value != null
                ? _catalogService.watchProducts(
                    categoryId: ProductCategoryCatalog.allId)
                : const Stream.empty()
            : null,
        builder: (context, snapshot) {
          final appleStyle = isAppleInterface(context);
          final products = snapshot.data ?? const <ProductComparison>[];
          final showComparisonsSection =
              _selectedHomeSection == HomeCatalogSection.comparisons;
          final showOffersSection =
              _selectedHomeSection == HomeCatalogSection.offers;
          final showCouponsSection =
              _selectedHomeSection == HomeCatalogSection.coupons;
          final showPlansSection =
              _selectedHomeSection == HomeCatalogSection.plans;
          final showAboutSection =
              _selectedHomeSection == HomeCatalogSection.about;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: appleStyle
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF8F8FB), Color(0xFFF1F2F7)],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppPalette.softOrange, Color(0xFFFFE7D1)],
                    ),
            ),
            child: RefreshIndicator(
              color: const Color(0xFFE8711A),
              onRefresh: _refreshCatalog,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: CompactHeaderSection(
                      currentUserLabel: userProfile.phoneNumber.isNotEmpty
                          ? userProfile.phoneNumber
                          : (widget
                                  .currentUser.email?.trim().isNotEmpty ==
                                  true
                              ? widget.currentUser.email!.trim()
                              : tr('مستخدم موثّق', 'Verified user')),
                      inviteCode: userProfile.inviteCode,
                      invitedFriendsCount: userProfile.invitedFriendsCount,
                      systemHealthLabel: systemHealth.statusLabel,
                      onInviteTap: () => _actions.inviteFriend(
                          context, userProfile, products),
                      onLogoutTap: () => _actions.signOut(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: HomeSectionSwitcher(
                        selectedSection: _selectedHomeSection,
                        onSectionSelected: _selectHomeSection,
                      ),
                    ),
                  ),
                  if (showComparisonsSection)
                    ...HomeSearchView.buildSlivers(
                      ref: ref,
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      onOpenExternalUrl: (url) =>
                          _actions.openExternalUrl(context, url),
                      onTapGroup: (group) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            group: group,
                            onOpenStore: (url) =>
                                _actions.openExternalUrl(context, url),
                          ),
                        ),
                      ),
                      onCopyCoupon: (code) =>
                          _actions.copyCouponCode(context, code),
                      isPaidPlanActive: isPaidPlanActive,
                      onDetectCityTap: () => unawaited(
                          _detectCityFromCurrentLocation(showFeedback: true)),
                      onBarcodeTap: () => _openBarcodeScanner(context),
                      onFilterTap: () => _showPriceFilter(context),
                    ),
                  if (showPlansSection)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PlanPickerSection(
                          isPaidActive: isPaidPlanActive,
                          visibleResultsCount: _trialVisibleResultsCount,
                          onWhatsAppTap: () => _actions.openExternalUrl(
                            context,
                            LeastPriceDataConfig.adminWhatsAppUrl,
                          ),
                        ),
                      ),
                    ),
                  if (!hasInternet)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.wifi_off_rounded,
                          title: tr('الاتصال غير متوفر', 'No connection'),
                          message: tr(
                            'سيعرض التطبيق آخر البيانات المحفوظة، وعند عودة الإنترنت يمكنك السحب للأسفل لتحديث الأسعار.',
                            'The app will show the latest saved data. Once the internet returns, pull down to refresh prices.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ),
                  if (!showComparisonsSection && !widget.firebaseReady)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'Firebase غير مهيأ',
                            'Firebase is not configured',
                          ),
                          message: tr(
                            'أضف إعدادات Firebase وملفات Android ثم أعد تشغيل التطبيق ليبدأ جلب المنتجات من Cloud Firestore.',
                            'Add Firebase settings and Android files, then restart the app to start loading products from Cloud Firestore.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    )
                  else if (!showComparisonsSection &&
                      snapshot.hasError &&
                      products.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'تعذر قراءة البيانات',
                            'Unable to read data',
                          ),
                          message: tr(
                            'لم نتمكن من الوصول إلى Cloud Firestore حالياً. تأكد من إعداد القاعدة والاتصال بالشبكة ثم جرّب مرة أخرى.',
                            'We could not reach Cloud Firestore right now. Check the database setup and your network, then try again.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: ExclusiveDealsSection(
                        stream: widget.firebaseReady
                            ? _catalogService.watchExclusiveDeals()
                            : Stream<List<ExclusiveDeal>>.value(
                                ExclusiveDeal.mockData),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: BrandOffersSection(),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: AdBannersSection(
                        banners: activeBanners,
                        onBannerTap: (_) => _actions.openExternalUrl(
                          context,
                          LeastPriceDataConfig.adminWhatsAppUrl,
                        ),
                      ),
                    ),
                  if (showCouponsSection && isPaidPlanActive)
                    SliverToBoxAdapter(
                      child: CouponsListSection(
                        stream: widget.firebaseReady
                            ? _catalogService.watchFeaturedCoupons()
                            : Stream<List<Coupon>>.value(Coupon.mockData),
                        onCopyCoupon: (code) =>
                            _actions.copyCouponCode(context, code),
                      ),
                    ),
                  if (showCouponsSection && !isPaidPlanActive)
                    SliverToBoxAdapter(
                      child: StreamBuilder<List<Coupon>>(
                        stream: _catalogService.watchFeaturedCoupons(),
                        builder: (context, snapshot) {
                          final count = (snapshot.data ?? [])
                              .where((c) =>
                                  c.active &&
                                  !c.isExpiredAt(DateTime.now()))
                              .length;
                          return CouponsPaywallSection(
                            couponCount: count,
                            onUpgradeTap: () =>
                                _selectHomeSection(HomeCatalogSection.plans),
                          );
                        },
                      ),
                    ),
                  if (showAboutSection)
                    SliverToBoxAdapter(
                      child: AboutLeastPriceSection(
                        onContactTap: () => _actions.openExternalUrl(
                          context,
                          LeastPriceDataConfig.adminWhatsAppUrl,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PriceFilterSheet extends StatefulWidget {
